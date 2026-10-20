#!/bin/bash
# Started by dle_up.sh, inside the private network namespace when that is in use. Brings the
# stack up from local images, model cache and repo, runs the hands-on, takes the screenshots,
# then tears everything down. Needs nothing from the network.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/dle_lib.sh"
trap teardown EXIT
log "stack: uid $(id -u), interfaces: $(awk 'NR > 2 { sub(":", "", $1); printf "%s ", $1 }' /proc/net/dev)"

# s3mock 3.12.0 ignores --server.address (its Jetty connector never gets a host) and binds every
# interface. Kept as documentation; the private namespace is what keeps it off the network.
start s3 --env-file "$S/env/s3.env" --pwd / --bind "$S/state/s3:/data" "$W/sif/s3.sif" \
  java -Djava.security.egd=file:/dev/./urandom -XX:+UseZGC -XX:+ZGenerational -Xmx1g -jar /s3mock.jar \
  --server.address=127.0.0.1
start opensearch --env-file "$S/env/os.env" --pwd /usr/share/opensearch \
  --bind "$S/state/os/data:/usr/share/opensearch/data" --bind "$S/state/os/logs:/usr/share/opensearch/logs" \
  --bind "$S/state/os/config:/usr/share/opensearch/config" "$S/sbx/opensearch" \
  bin/opensearch -Ediscovery.type=single-node -Eplugins.security.disabled=true \
  -Enetwork.host=127.0.0.1 -Ehttp.port=9200 -Etransport.port=9300 -Ebootstrap.memory_lock=false \
  -Enode.store.allow_mmap=false
wait_http s3 http://127.0.0.1:9090/ 180
start registry --env-file "$S/env/registry.env" --pwd /app "$W/sif/registry.sif" \
  uvicorn hpdf_xcard_registry.registry_api:app --host 127.0.0.1 --port 18100
wait_http registry http://127.0.0.1:18100/readyz 180

log "seed: corpus through the registry, then the hackathon documents"
apptainer exec "${AX[@]}" --env-file "$S/env/seed.env" --pwd /app \
  --bind "$W/repo/seed_registry.py:/seed_registry.py" \
  --bind "$W/repo/load_hackathon_materials.py:/load_hackathon_materials.py" \
  --bind "$W/repo/hackathon:/hackathon" "$W/sif/api.sif" \
  sh -c 'python /seed_registry.py; rc=$?; python /load_hackathon_materials.py || echo "hackathon materials not loaded; the engine is fine without them"; exit $rc' \
  > "$RUN/logs/seed.log" 2>&1 || fail "seed"
grep -E "seeded|skipped|failed|wrote" "$RUN/logs/seed.log"

wait_http opensearch http://127.0.0.1:9200/_cluster/health 300
start api --env-file "$S/env/api.env" --pwd /app --bind "$S/state/engine:/app/data" \
  --bind "$W/cache/fastembed:/fastembed" \
  --bind "$W/repo/hackathon:/hackathon" --bind "$W/repo/load_hackathon_materials.py:/load_hackathon_materials.py" \
  "$W/sif/api.sif" uvicorn apps.api.main:app --host 127.0.0.1 --port 18000
wait_http api http://127.0.0.1:18000/health 900
start ui --pwd / "$W/sif/ui.sif" nginx -e stderr -c "$S/state/ui/nginx.conf" -g "daemon off;"
wait_http ui http://127.0.0.1:15173/ 60
hostname > "$RUN/NODE"; touch "$RUN/STACK_UP"
log "stack up on $(hostname)"

# ------------------------------------------------------------------ hands-on --
take_shots() {  # take_shots before|after: headless Chromium (Playwright image) against the UI
  [ "$SHOTS" = 1 ] || return 0
  mkdir -p "$RUN/out/shots"
  log "screenshots: $1"
  apptainer exec "${AX[@]}" --env PYTHONPATH=/pwlib --bind "$W/cache/pwlib:/pwlib" \
    --bind "$HERE:/stage" --bind "$RUN/out/shots:/shots" "$W/sif/pw.sif" \
    python3 /stage/shots.py /shots "$1" > "$RUN/logs/shots-$1.log" 2>&1 || log "screenshots $1: exit $?"
  grep '^shot ' "$RUN/logs/shots-$1.log"
}
source "$HERE/dle_handson.sh"

if [ "$HOLD_MIN" -gt 0 ]; then
  log "holding the stack $HOLD_MIN min on $(hostname). From a laptop (ALCF MFA prompts once):"
  log "  ssh -J $USER@polaris.alcf.anl.gov -L 15173:127.0.0.1:15173 -L 18000:127.0.0.1:18000 -L 18100:127.0.0.1:18100 $USER@$(hostname)"
  end=$(( $(date +%s) + HOLD_MIN * 60 ))
  while [ "$(date +%s)" -lt "$end" ]; do
    sleep 60
    curl -fs -o /dev/null --max-time 5 http://127.0.0.1:18000/health || { log "api stopped answering"; break; }
  done
fi
log "stack done"
