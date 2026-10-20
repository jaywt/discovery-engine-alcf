#!/bin/bash -l
# discovery-local (github.com/AI-ModCon/discovery-local) on one ALCF Polaris compute node.
#
# The repo ships a Docker Compose v2 stack. Polaris has no Docker and no root, so this runs the
# same images, pinned by digest, as unprivileged Apptainer processes on one node:
#
#   s3          127.0.0.1:9090    s3mock, the registry's only storage backend
#   opensearch  127.0.0.1:9200    BM25 + kNN hybrid search
#   registry    127.0.0.1:18100   the real xCard Registry
#   seed        (one-shot)        pushes the bundled corpus through the registry, loads hackathon docs
#   api         127.0.0.1:18000   the Discovery Engine (fastembed bge-small embeddings)
#   ui          127.0.0.1:15173   the engine's web UI (nginx)
#
# Not ported: registry-https (Caddy). It only serves catalog links, and the catalog is off locally.
#
# This script does everything that needs the network: it pulls the images, fetches the embedding
# model once and clones the repo. dle_stack.sh then runs the stack, the hands-on (dle_handson.sh)
# and, with SHOTS=1, headless screenshots of the UI (shots.py).
#
# dle_stack.sh runs in a private network namespace (netns.py) whose only interface is loopback,
# so no service is reachable from the rest of the machine. s3mock binds every interface whatever
# it is told, so this is what keeps it private. If the namespace check fails, if the engine cannot
# load the model offline, or if HOLD_MIN>0 (an SSH tunnel needs the host loopback), the stack
# runs on the host loopback as before. NETNS=0 forces the host loopback.
#
#   CARD=path/to/card.xcard.md CARD_ID=<spine id> [SHOTS=1] [HOLD_MIN=60] [NETNS=0] dle_up.sh
set -uo pipefail
T0=$(date +%s)
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/dle_lib.sh"
JOB=${PBS_JOBID%%.*}; JOB=${JOB:-manual$$}
RUN=$W/runs/$JOB
CARD=${CARD:-$W/stage/card.xcard.md}
CARD_ID=${CARD_ID:-emma-benchmark}
HOLD_MIN=${HOLD_MIN:-0}
SHOTS=${SHOTS:-1}
NETNS=${NETNS:-1}
mkdir -p "$RUN/logs" "$RUN/out" "$W/sif" "$W/cache/fastembed"
exec > >(tee -a "$RUN/job.log") 2>&1
trap teardown EXIT

module use /soft/modulefiles >/dev/null 2>&1
module load spack-pe-base apptainer >/dev/null 2>&1
command -v apptainer >/dev/null || fail "apptainer not found"
export http_proxy=$P https_proxy=$P HTTP_PROXY=$P HTTPS_PROXY=$P
export no_proxy=127.0.0.1,localhost NO_PROXY=127.0.0.1,localhost
export APPTAINER_CACHEDIR=$S/cache APPTAINER_TMPDIR=$S/tmp
fresh_state() {  # empty service state; the OpenSearch config is copied in once the sandbox exists
  rm -rf "$S/state" "$RUN/STACK_UP"
  mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR" "$S/state"/{s3,home,engine,os/data,os/logs,ui}
  [ -d "$S/sbx/opensearch/usr/share/opensearch/config" ] && cp -r "$S/sbx/opensearch/usr/share/opensearch/config" "$S/state/os/config"
  write_nginx_conf
}
fresh_state
[ -s "$CARD" ] || fail "no card at $CARD"
log "host $(hostname) job $JOB $(apptainer --version) cores $(nproc) mem $(free -g | awk '/Mem/{print $2}')G"
write_env_files

# ------------------------------------------------------------------ images --
want=(s3 opensearch registry api ui); [ "$SHOTS" = 1 ] && want+=(pw)
for k in "${want[@]}"; do
  if [ -s "$W/sif/$k.sif" ]; then log "image $k: cached"; continue; fi
  log "image $k: pulling ${IMG[$k]}"
  apptainer pull -F "$W/sif/$k.sif.$JOB" "docker://${IMG[$k]}" > "$RUN/logs/pull-$k.log" 2>&1 || fail "pull $k"
  mv -f "$W/sif/$k.sif.$JOB" "$W/sif/$k.sif"
done
ls -l "$W"/sif/*.sif

# OpenSearch's tree is owned by uid 1000 in the image. An unprivileged sandbox build makes it
# ours, so its config dir can be copied out and bind-mounted writable.
if [ ! -x "$S/sbx/opensearch/usr/share/opensearch/bin/opensearch" ]; then
  log "opensearch: unpacking sandbox"
  rm -rf "$S/sbx/opensearch"; mkdir -p "$S/sbx"
  apptainer build -F --sandbox "$S/sbx/opensearch" "$W/sif/opensearch.sif" > "$RUN/logs/sandbox.log" 2>&1 \
    || fail "sandbox build"
fi
fresh_state

# ------------------------------------------------------------------ repo --
[ -d "$W/repo/.git" ] || git clone -q https://github.com/AI-ModCon/discovery-local "$W/repo" || fail "clone"
git -C "$W/repo" fetch -q origin 2>/dev/null
git -C "$W/repo" checkout -q "$REPO_COMMIT" || fail "checkout $REPO_COMMIT"
log "repo at $(git -C "$W/repo" log -1 --format='%h %ad %s' --date=short)"

# ------------------------------------------------------------------ embedding model --
# Left to itself the engine fetches the model from Hugging Face on every start. Fetch it once
# into a persistent cache, then check it loads with HF_HUB_OFFLINE=1 and no proxy.
embed() {  # embed ENV-FILE: load the model from /fastembed and embed one string
  apptainer exec "${AX[@]}" --env-file "$1" --bind "$W/cache/fastembed:/fastembed" "$W/sif/api.sif" python -c \
    "from fastembed import TextEmbedding as T; m = T('$EMBED_MODEL', cache_dir='/fastembed'); print('$EMBED_MODEL dim', len(next(iter(m.embed(['ok'])))))"
}
if [ -z "$(ls -A "$W/cache/fastembed" 2>/dev/null)" ]; then
  log "embedding model: fetching $EMBED_MODEL"
  embed "$S/env/proxy.env" > "$RUN/logs/model-fetch.log" 2>&1 || fail "model fetch"
fi
printf '%s\n' HF_HUB_OFFLINE=1 https_proxy=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 > "$S/env/offline.env"
if embed "$S/env/offline.env" > "$RUN/logs/model-offline.log" 2>&1; then
  OFFLINE=1; log "embedding model: $(tail -n 1 "$RUN/logs/model-offline.log"), loads offline ($(du -sh "$W/cache/fastembed" | cut -f1))"
else
  OFFLINE=0; log "embedding model: does not load offline, the engine will fetch it: $(tail -n 2 "$RUN/logs/model-offline.log" | tr '\n' ' ' | cut -c1-300)"
  sed -i '/^HF_HUB_OFFLINE=/d' "$S/env/api.env"
fi

# The Playwright image ships Chromium in /ms-playwright but not the Python package (its build
# venv is deleted). Install the matching release once into a persistent dir on PYTHONPATH.
if [ "$SHOTS" = 1 ] && [ ! -e "$W/cache/pwlib/playwright/__init__.py" ]; then
  log "screenshots: installing playwright==$PW_VERSION"
  rm -rf "$W/cache/pwlib"
  apptainer exec "${AX[@]}" --env-file "$S/env/proxy.env" --bind "$W/cache:/wcache" "$W/sif/pw.sif" \
    python3 -m pip install --no-cache-dir --target /wcache/pwlib "playwright==$PW_VERSION" > "$RUN/logs/pw-install.log" 2>&1 \
    || { log "screenshots: playwright install failed, skipping them: $(tail -n 2 "$RUN/logs/pw-install.log" | tr '\n' ' ')"; SHOTS=0; }
fi

# ------------------------------------------------------------------ network --
NS=(); MODE=host
if [ "$HOLD_MIN" -gt 0 ]; then log "network: host loopback (HOLD_MIN=$HOLD_MIN, for the SSH tunnel)"
elif [ "$NETNS" = 0 ]; then log "network: host loopback (NETNS=0)"
elif [ "$OFFLINE" = 0 ]; then log "network: host loopback (the engine needs the network for its model)"
elif netns_selftest; then NS=(python3 "$HERE/netns.py"); MODE=private; log "network: private namespace, loopback only"
else log "network: host loopback (namespace check failed)"; fi

# ------------------------------------------------------------------ stack --
export T0 JOB RUN CARD CARD_ID HOLD_MIN SHOTS DLE_HOME=$W DLE_SCRATCH=$S
run_stack() {
  export MODE; echo "$MODE" > "$RUN/NETWORK"
  "${NS[@]}" bash "$HERE/dle_stack.sh" &
  local child=$!
  # From outside the stack's network: what can the rest of the machine reach?
  while [ ! -e "$RUN/STACK_UP" ] && kill -0 $child 2>/dev/null; do sleep 2; done
  if [ -e "$RUN/STACK_UP" ]; then
    local ips ip port
    ips=$( (hostname -I 2>/dev/null || hostname -i) | tr ' ' '\n' | grep -E '^[0-9.]+$' | grep -v '^127\.' | head -2)
    { echo "network: $MODE. HTTP status from the host, outside the stack; 000 = nothing answered."
      for ip in 127.0.0.1 $ips; do
        for port in 9090 9191 9200 15173 18000 18100; do
          printf '%s:%s %s\n' "$ip" "$port" "$(curl --noproxy '*' -s -o /dev/null --max-time 3 -w '%{http_code}' "http://$ip:$port/")"
        done
      done; } > "$RUN/out/13_exposure.txt"
    log "exposure: $(tail -n +2 "$RUN/out/13_exposure.txt" | tr '\n' ' ')"
  fi
  wait $child
}
run_stack; rc=$?
if [ $rc != 0 ] && [ "$MODE" = private ] && [ ! -e "$RUN/STACK_UP" ]; then
  log "stack did not come up in the private namespace (exit $rc); once more on the host loopback"
  mkdir -p "$RUN/logs/netns-attempt"; mv "$RUN"/logs/{s3,opensearch,registry,seed,api,ui}.log "$RUN/logs/netns-attempt/" 2>/dev/null
  NS=(); MODE=host-fallback; fresh_state
  run_stack; rc=$?
fi

if [ -d "$RUN/out/shots" ]; then
  tar -C "$RUN/out" -czf "$RUN/shots.tgz" shots && base64 -w0 "$RUN/shots.tgz" > "$RUN/shots.tgz.b64" \
    && (cd "$RUN" && sha256sum shots.tgz > shots.tgz.sha256)
  log "screenshots: $(ls "$RUN/out/shots" | grep -c png) PNGs, $(du -h "$RUN/shots.tgz" | cut -f1) packed"
fi
log "done (stack exit $rc)"
exit $rc
