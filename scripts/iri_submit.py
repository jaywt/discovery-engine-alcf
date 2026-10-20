"""Submit the Discovery Engine job to ALCF Polaris through the ALCF IRI API, without SSH.

    export IRI_TOKEN_ALCF=...            # a Globus access token for the ALCF IRI API
    export ALCF_USER=you ALCF_PROJECT=YourProject
    uv run --with httpx scripts/iri_submit.py submit scripts/ card/my.xcard.md --queue debug --minutes 30
    uv run --with httpx scripts/iri_submit.py status <job-id>
    uv run --with httpx scripts/iri_submit.py view /home/you/discovery-local/logs/dle.out
    uv run --with httpx scripts/iri_submit.py ls /home/you/discovery-local/runs/<job>/out
    uv run --with httpx scripts/iri_submit.py fetch /home/you/discovery-local/runs/<job>/shots.tgz.b64 shots.tgz
    uv run --with httpx scripts/iri_submit.py cancel <job-id>

Why it ships files the way it does: IRI's file upload answered 501 (not implemented) and a
multi-line script passed as `bash -lc` arrived empty. So `submit` packs the stage directory and
the card into one gzip+base64 tar inside a single-line command, and the node checks every file
with sha256sum before running dle_up.sh. The payload limit is the command-line length (~128 KB).
IRI's download answered 501 too, and `view` returns text, so binary results (the screenshots) are
packed on the node as base64; `fetch` pages that through `view`, decodes it and checks its sha256.

The token is read from the environment and never printed.
"""
import argparse, base64, hashlib, io, json, os, pathlib, sys, tarfile, time

import httpx

API = "https://api.alcf.anl.gov/api/v1"
POLARIS = "55c1c993-1124-47f9-b823-514ba3849a9a"
STORAGE = {"home": "6115bd2c-957a-4543-abff-5fae52992ff2", "eagle": "1c3ad9d4-2e91-42bc-becb-72b1fde1235c"}
STAGE_FILES = ("dle_up.sh", "dle_lib.sh", "dle_stack.sh", "dle_handson.sh", "netns.py", "nscheck.sh", "shots.py")


def client():
    tok = os.environ.get("IRI_TOKEN_ALCF", "").strip()
    if not tok:
        sys.exit("Set IRI_TOKEN_ALCF to an ALCF IRI access token.")
    return httpx.Client(timeout=120, headers={"Authorization": f"Bearer {tok}", "Accept": "application/json"})


def ok(r):
    if r.status_code >= 400:
        sys.exit(f"HTTP {r.status_code} {r.request.method} {r.url.path}: {r.text[:600]}")
    return r.json() if r.content else {}


def storage(path):
    return STORAGE["eagle"] if path.startswith(("/eagle", "/lus/eagle")) else STORAGE["home"]


def wait_task(c, r):
    """Filesystem calls return a task id; poll it until it settles."""
    tid = r.get("task_id") if isinstance(r, dict) else None
    for _ in range(90 if tid else 0):
        t = ok(c.get(f"{API}/task/{tid}"))
        if t.get("status") in ("completed", "failed", "canceled"):
            return t
        time.sleep(2)
    return r


def submit(a):
    user, project = os.environ.get("ALCF_USER"), os.environ.get("ALCF_PROJECT")
    if not (user and project):
        sys.exit("Set ALCF_USER and ALCF_PROJECT.")
    home = f"/home/{user}/discovery-local"
    stage = pathlib.Path(a.stage)
    files = {n: (stage / n).read_bytes() for n in STAGE_FILES}
    files["card.xcard.md"] = pathlib.Path(a.card).read_bytes()
    sums = "".join(f"{hashlib.sha256(b).hexdigest()}  {n}\n" for n, b in files.items())
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz", compresslevel=9) as tf:
        for n, b in [*files.items(), ("SHA256SUMS", sums.encode())]:
            ti = tarfile.TarInfo(n); ti.size = len(b); ti.mode = 0o644; tf.addfile(ti, io.BytesIO(b))
    payload = base64.b64encode(buf.getvalue()).decode()
    env = " ".join(f"{k}={v}" for k, v in (("CARD", f"{home}/stage/card.xcard.md"), ("CARD_ID", a.card_id),
                                           ("HOLD_MIN", a.hold), ("SHOTS", "0" if a.no_shots else ""),
                                           ("NETNS", "0" if a.host_network else ""), ("DLE_HOME", home)) if v)
    cmd = (f"mkdir -p {home}/stage {home}/logs && echo {payload} | base64 -d | tar xzf - -C {home}/stage"
           f" && cd {home}/stage && sha256sum -c SHA256SUMS && {env} exec bash -l {home}/stage/dle_up.sh")
    spec = {"name": a.name, "executable": "/bin/bash", "arguments": ["-lc", cmd], "directory": home,
            "resources": {"node_count": 1},
            "attributes": {"duration": a.minutes * 60, "queue_name": a.queue, "account": project,
                           "custom_attributes": {"filesystems": "home:eagle"}},
            "stdout_path": f"{home}/logs/{a.name}.out", "stderr_path": f"{home}/logs/{a.name}.err"}
    print(f"{len(files)} files, {len(payload)} base64 chars", file=sys.stderr)
    with client() as c:
        print(json.dumps(ok(c.post(f"{API}/compute/job/{POLARIS}", json=spec))))


def fetch(a, step=4_000_000):
    """Page a base64 file through `view`, decode it, and check it against <path minus .b64>.sha256."""
    parts = []
    with client() as c:
        while True:
            t = wait_task(c, ok(c.get(f"{API}/filesystem/view/{storage(a.path)}",
                                      params={"path": a.path, "size": step, "offset": sum(map(len, parts))})))
            if t.get("status") != "completed":
                sys.exit(f"view failed: {json.dumps(t)[:400]}")
            out = t["result"].get("output", t["result"])
            parts.append(out["content"] if isinstance(out, dict) else out)
            if len(parts[-1]) < step:
                break
        want = ""
        if a.path.endswith(".b64"):
            s = wait_task(c, ok(c.get(f"{API}/filesystem/view/{storage(a.path)}", params={"path": a.path[:-4] + ".sha256"})))
            if s.get("status") == "completed":
                o = s["result"].get("output", s["result"])
                want = (o["content"] if isinstance(o, dict) else o).split()[0]
    data = base64.b64decode("".join(parts).strip())
    pathlib.Path(a.local).write_bytes(data)
    got = hashlib.sha256(data).hexdigest()
    print(f"{a.local}: {len(data)} bytes, sha256 {got}" + (f" ({'matches' if got == want else 'DOES NOT MATCH'} the node's)" if want else ""))
    if want and got != want:
        sys.exit(1)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sp = p.add_subparsers(dest="cmd", required=True)
    s = sp.add_parser("submit"); s.add_argument("stage"); s.add_argument("card")
    s.add_argument("--card-id", default="", help="the card's spine id, for the read-back step")
    s.add_argument("--queue", default="debug"); s.add_argument("--minutes", type=int, default=30)
    s.add_argument("--hold", default="", help="minutes to keep the stack up after the hands-on")
    s.add_argument("--no-shots", action="store_true", help="skip the UI screenshots")
    s.add_argument("--host-network", action="store_true", help="skip the private network namespace")
    s.add_argument("--name", default="dle")
    f = sp.add_parser("fetch", help="download a base64 text file written on the node, decoded")
    f.add_argument("path"); f.add_argument("local")
    for n in ("status", "cancel"):
        sp.add_parser(n).add_argument("job")
    for n in ("view", "ls"):
        sp.add_parser(n).add_argument("path")
    a = p.parse_args()
    if a.cmd == "submit":
        return submit(a)
    if a.cmd == "fetch":
        return fetch(a)
    with client() as c:
        if a.cmd == "status":
            print(json.dumps(ok(c.get(f"{API}/compute/status/{POLARIS}/{a.job}")), indent=1))
        elif a.cmd == "cancel":
            r = c.delete(f"{API}/compute/cancel/{POLARIS}/{a.job}"); print(r.status_code, r.text[:300])
        else:
            t = wait_task(c, ok(c.get(f"{API}/filesystem/{a.cmd}/{storage(a.path)}", params={"path": a.path})))
            out = t.get("result", t)
            out = out.get("output", out) if isinstance(out, dict) else out
            if isinstance(out, dict) and "content" in out:
                print(out["content"], end="")
            elif a.cmd == "ls" and isinstance(out, list):
                for f in sorted(out, key=lambda f: f["name"]):
                    print(f"{int(f.get('size', 0)):>10}  {f['name']}")
            else:
                print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
