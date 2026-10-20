# Sourced by dle_up.sh and dle_stack.sh. Paths, pinned images, env files, and process helpers.
W=${DLE_HOME:-$HOME/discovery-local}          # persistent: SIF images, model cache, repo, run outputs
S=${DLE_SCRATCH:-/local/scratch/$USER/dle}    # node-local, wiped each run: service state, OpenSearch sandbox
REPO_COMMIT=f88a6097f3cddca84aa57d6f44edd0b5d5039ab1
P=http://proxy.alcf.anl.gov:3128

# Same images and tags as the repo's .env and compose.yaml, resolved to digests on 2026-10-16.
# OpenSearch comes from public.ecr.aws (same digest as Docker Hub) to avoid Docker Hub's
# anonymous pull limit, which a shared proxy address hits easily.
declare -A IMG=(
  [s3]=docker.io/adobe/s3mock@sha256:9da9c179bc0d1cb6986a40fd7ffbbc6deee11522b3892217ca350d65596126fa
  [opensearch]=public.ecr.aws/opensearchproject/opensearch@sha256:1193b7c29c5d63028523728243cc4da047ac49f697a8f8105e5aeee2f89bcc4c
  [registry]=ghcr.io/ai-modcon/xcard-registry@sha256:e5703b8bb0fca6126c2180799036ce1ba8292c2d8279b45d5a3c5fa96a8ebe00
  [api]=ghcr.io/ai-modcon/genesis-discovery-api@sha256:c568b3ea3379956b4167df2338c5c4a71e702eb4acb26889f61c0438dfb15452
  [ui]=ghcr.io/ai-modcon/genesis-discovery-ui@sha256:75080eda8f25b68667994d15f91954915ab945c98de66df25d02fcc64cc70556
  # Not part of the stack: headless Chromium for the UI screenshots (SHOTS=1).
  [pw]=mcr.microsoft.com/playwright/python@sha256:acc6300abda1a16dba3a0d39583c8be53e619a3f23d4a0eeeb8de0a9275c47ac
)
EMBED_MODEL=BAAI/bge-small-en-v1.5
PW_VERSION=1.48.0   # must match the pw image (v1.48.0-noble), whose browsers it drives

log() { echo "[$(date +%H:%M:%S) +$(( $(date +%s) - T0 ))s] $*"; }
PIDS=()
teardown() {
  [ "${TORN:-}" ] && return; TORN=1
  log "teardown"
  for p in "${PIDS[@]}"; do kill "$p" 2>/dev/null; done
  sleep 5
  for p in "${PIDS[@]}"; do kill -9 "$p" 2>/dev/null; done
  pkill -u "$(id -un)" -f "$S/" 2>/dev/null
}
fail() {
  log "FAILED: $*"
  for f in "$RUN"/logs/*.log; do echo "----- tail $f"; tail -n 40 "$f"; done
  teardown; exit 1
}
# A private network namespace (netns.py), trusted only once nscheck.sh passes inside it:
# our own uid, loopback the only interface and working, Apptainer still able to run an image.
netns_selftest() {
  python3 "$HERE/netns.py" bash "$HERE/nscheck.sh" "$(id -u)" "$W/sif/ui.sif" > "$RUN/logs/netns.log" 2>&1
  local rc=$?; log "netns check: exit $rc, $(tail -n 2 "$RUN/logs/netns.log" | tr '\n' ' ' | cut -c1-300)"
  return $rc
}

# --cleanenv: only the env file gets in. --home: a scratch home, so the real one stays clean.
AX=(--cleanenv --home "$S/state/home" --bind "$S" --bind /tmp)
start() {  # start NAME APPTAINER-ARGS... ; background, logs to $RUN/logs/NAME.log
  local name=$1; shift
  apptainer exec "${AX[@]}" "$@" > "$RUN/logs/$name.log" 2>&1 &
  PIDS+=($!); log "started $name (pid $!)"
}
wait_http() {  # wait_http NAME URL SECONDS
  local name=$1 url=$2 n=$3 i
  for ((i = 0; i < n; i += 3)); do
    curl -fs -o /dev/null --max-time 5 "$url" && { log "$name ready ($url)"; return 0; }
    sleep 3
  done
  fail "$name not ready after ${n}s ($url)"
}

write_env_files() {
  mkdir -p "$S/env"
  printf '%s\n' "http_proxy=$P" "https_proxy=$P" "HTTP_PROXY=$P" "HTTPS_PROXY=$P" \
    "no_proxy=127.0.0.1,localhost" "NO_PROXY=127.0.0.1,localhost" > "$S/env/proxy.env"
  # compose.yaml's storage block. Service name "s3" becomes 127.0.0.1: Apptainer shares the host network.
  printf '%s\n' XCARD_STORAGE_BUCKET=xcards XCARD_STORAGE_PREFIX=registry \
    XCARD_STORAGE_ENDPOINT_URL=http://127.0.0.1:9090 AWS_REGION=us-east-1 \
    AWS_ACCESS_KEY_ID=xcard-local-access AWS_SECRET_ACCESS_KEY=xcard-local-secret-key > "$S/env/storage.env"
  { cat "$S/env/proxy.env"; printf '%s\n' initialBuckets=xcards root=/data retainFilesOnExit=true; } > "$S/env/s3.env"
  { cat "$S/env/proxy.env"; echo 'OPENSEARCH_JAVA_OPTS="-Xms512m -Xmx512m"'; } > "$S/env/os.env"
  { cat "$S/env/proxy.env" "$S/env/storage.env"; printf '%s\n' \
      XCARD_STORAGE_RECORD_WRITE_VERSION=4 \
      XCARD_ENABLED_TYPES=data_card,model_card,agent_card,resource_card \
      XCARD_VALIDATION_PROFILES=datacard-linkml,xcard-genesis-spine \
      XCARD_CATALOG_ENABLED=false XCARD_CATALOG_COORDINATION_ENABLED=false XCARD_CATALOG_REPLAY_ENABLED=false \
      XCARD_CATALOG_ELIGIBILITY_POLICY=all-validated XCARD_CATALOG_CONTRACT_VERSION=amsc-artifact-v1 \
      XCARD_CATALOG_BASE_URL=https://api.ds.dev.american-science-cloud.org/api/current \
      XCARD_CATALOG_NAME=hpdf-xcard-registry-storage.hpdf-xcard-registry-data-catalog \
      XCARD_CATALOG_PARENT_FQN=hpdf-xcard-registry-storage.hpdf-xcard-registry-data-catalog \
      XCARD_REGISTRY_INSTANCE=hpdf-xcard-registry-ds-dev \
      XCARD_PUBLIC_REGISTRY_BASE_URL=https://localhost:18443/api/current \
      XCARD_CATALOG_TOKEN=; } > "$S/env/registry.env"
  # The embedding model is fetched once by dle_up.sh into $W/cache/fastembed (bound at /fastembed),
  # so the engine starts offline. That is what lets the stack run in a namespace with no network.
  { cat "$S/env/proxy.env" "$S/env/storage.env"; printf '%s\n' \
      GENESIS_SETTINGS_SECRET=local-only XCARD_REGISTRY_URL=http://127.0.0.1:18100 \
      SEED_CORPUS=/app/cards/xcard SEED_LIMIT=0 SEED_FORCE= HACKATHON_CARDS=/hackathon; } > "$S/env/seed.env"
  # compose.yaml also sets NODE_TLS_REJECT_UNAUTHORIZED=0 and PYTHONHTTPSVERIFY=0 for the ORNL
  # Netskope proxy ("REMOVE AFTER THE EVENT"). ALCF's proxy does not re-sign TLS; left out.
  { cat "$S/env/proxy.env" "$S/env/storage.env"; printf '%s\n' \
      GENESIS_SETTINGS_SECRET=local-only GENESIS_CARD_SOURCE=registry \
      XCARD_REGISTRY_URL=http://127.0.0.1:18100 GLOBUS_AUTH_ENABLED=false GENESIS_GATEWAY_AUTH=false \
      GENESIS_ENABLE_AMSC_CATALOG=0 GENESIS_USE_OPENSEARCH=1 OPENSEARCH_URL=http://127.0.0.1:9200 \
      OPENSEARCH_INDEX=genesis-cards EMBEDDING_PROVIDER=fastembed GENESIS_EMBED_MODEL=$EMBED_MODEL \
      GENESIS_EMBED_CACHE=/fastembed HF_HUB_OFFLINE=1 \
      GENESIS_SETTINGS_DB=/app/data/user_settings.db GENESIS_AMSC_BASE_URL= \
      GENESIS_ARGO_BASE_URL=http://127.0.0.1:44497 GENESIS_ALCF_BASE_URL=http://127.0.0.1:4000 \
      GENESIS_LOG_LEVEL=INFO; } > "$S/env/api.env"
}

write_nginx_conf() {
  # The UI image's conf.d/default.conf, moved off port 80 (needs root) and pointed at
  # 127.0.0.1:18000 instead of the compose host "api". Pid, temp and log paths on scratch.
  local U=$S/state/ui
  mkdir -p "$U/tmp"
  cat > "$U/nginx.conf" <<EOF
worker_processes 2;
pid $U/nginx.pid;
error_log stderr notice;
events { worker_connections 1024; }
http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  access_log $U/access.log;
  client_body_temp_path $U/tmp/body;
  proxy_temp_path $U/tmp/proxy;
  fastcgi_temp_path $U/tmp/fastcgi;
  uwsgi_temp_path $U/tmp/uwsgi;
  scgi_temp_path $U/tmp/scgi;
  sendfile on;
  server {
    listen 127.0.0.1:15173;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript;
    gzip_min_length 1000;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    location /api/ {
      proxy_pass http://127.0.0.1:18000/api/;
      proxy_http_version 1.1;
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto \$scheme;
      proxy_read_timeout 120s;
    }
    location /health { proxy_pass http://127.0.0.1:18000/health; }
    location /assets/ { expires 1y; add_header Cache-Control "public, immutable"; }
    location / { try_files \$uri \$uri/ /index.html; }
    location ~ /\. { deny all; }
  }
}
EOF
}
