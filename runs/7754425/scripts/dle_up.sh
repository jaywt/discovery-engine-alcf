#!/bin/bash -l
# discovery-local (github.com/AI-ModCon/discovery-local) on one ALCF Polaris compute node.
#
# The repo ships a Docker Compose v2 stack. Polaris has no Docker and no root, so this runs the
# same images, pinned by digest, as unprivileged Apptainer processes on the node's loopback:
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
# Then it runs the hands-on (dle_handson.sh): count the seeded corpus, search, register a data
# card, resync, read it back, search again. Results land in runs/<job>/out.
# HOLD_MIN>0 keeps the stack up that long afterwards, for an SSH tunnel to the UI.
set -uo pipefail
T0=$(date +%s)
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/dle_lib.sh"
JOB=${PBS_JOBID%%.*}; JOB=${JOB:-manual$$}
RUN=$W/runs/$JOB
CARD=${CARD:-$W/stage/emma.xcard.md}
CARD_ID=${CARD_ID:-emma-benchmark}
HOLD_MIN=${HOLD_MIN:-0}
mkdir -p "$RUN/logs" "$RUN/out" "$W/sif"
exec > >(tee -a "$RUN/job.log") 2>&1
trap teardown EXIT

module use /soft/modulefiles >/dev/null 2>&1
module load spack-pe-base apptainer >/dev/null 2>&1
command -v apptainer >/dev/null || fail "apptainer not found"
export http_proxy=$P https_proxy=$P HTTP_PROXY=$P HTTPS_PROXY=$P
export no_proxy=127.0.0.1,localhost NO_PROXY=127.0.0.1,localhost
export APPTAINER_CACHEDIR=$S/cache APPTAINER_TMPDIR=$S/tmp
rm -rf "$S/state"
mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR" "$S/state"/{s3,home,engine,os/data,os/logs,ui}
ulimit -n "$(ulimit -Hn)" 2>/dev/null || true
[ -s "$CARD" ] || fail "no card at $CARD"
log "host $(hostname) job $JOB $(apptainer --version) cores $(nproc) mem $(free -g | awk '/Mem/{print $2}')G"

# ------------------------------------------------------------------ images --
for k in s3 opensearch registry api ui; do
  if [ -s "$W/sif/$k.sif" ]; then log "image $k: cached"; continue; fi
  log "image $k: pulling ${IMG[$k]}"
  apptainer pull -F "$W/sif/$k.sif" "docker://${IMG[$k]}" > "$RUN/logs/pull-$k.log" 2>&1 || fail "pull $k"
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
cp -r "$S/sbx/opensearch/usr/share/opensearch/config" "$S/state/os/config"

# ------------------------------------------------------------------ repo --
[ -d "$W/repo/.git" ] || git clone -q https://github.com/AI-ModCon/discovery-local "$W/repo" || fail "clone"
git -C "$W/repo" fetch -q origin 2>/dev/null
git -C "$W/repo" checkout -q "$REPO_COMMIT" || fail "checkout $REPO_COMMIT"
log "repo at $(git -C "$W/repo" log -1 --format='%h %ad %s' --date=short)"

write_env_files
write_nginx_conf

# ------------------------------------------------------------------ bring-up --
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
  --bind "$W/repo/hackathon:/hackathon" --bind "$W/repo/load_hackathon_materials.py:/load_hackathon_materials.py" \
  "$W/sif/api.sif" uvicorn apps.api.main:app --host 127.0.0.1 --port 18000
wait_http api http://127.0.0.1:18000/health 900
start ui --pwd / "$W/sif/ui.sif" nginx -e stderr -c "$S/state/ui/nginx.conf" -g "daemon off;"
wait_http ui http://127.0.0.1:15173/ 60
hostname > "$RUN/NODE"
log "stack up on $(hostname)"

# ------------------------------------------------------------------ hands-on --
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
log "done"
