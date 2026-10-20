# Sourced by dle_stack.sh once the stack is up. The deck's hands-on, as API calls, saved to $O.
O=$RUN/out
E=http://127.0.0.1:18000
R=http://127.0.0.1:18100
J='Content-Type: application/json'

{
  echo "node: $(hostname)"; echo "date: $(date -Is)"; echo "job: $JOB"
  echo "apptainer: $(apptainer --version)"; echo "repo: AI-ModCon/discovery-local@$REPO_COMMIT"
  for k in s3 opensearch registry api ui; do echo "image $k: ${IMG[$k]}"; done
  [ "$SHOTS" = 1 ] && echo "image pw (screenshots only): ${IMG[pw]}"
  echo "network: $MODE"; echo "embedding model: $EMBED_MODEL"
  echo "card: $(basename "$CARD") sha256 $(sha256sum "$CARD" | cut -d' ' -f1)"
} > "$O/00_versions.txt"
ss -ltnH 2>/dev/null | awk '{print $4}' | grep -E ':(9090|9191|9200|9300|18000|18100|15173)$' | sort > "$O/01_listening.txt"
curl -s $E/health > "$O/01_engine_health.json"
curl -s $R/readyz > "$O/01_registry_readyz.json"
curl -s http://127.0.0.1:9200/_cluster/health > "$O/01_opensearch_health.json"

ncards() { curl -s "$E/api/v1/cards?limit=5000" | python3 -c 'import sys,json;print(len(json.load(sys.stdin)))' 2>/dev/null || echo 0; }
# Indexing can lag the health check, so wait until the count stops moving.
prev=-1
for i in $(seq 1 40); do n=$(ncards); [ "$n" = "$prev" ] && [ "$n" -gt 0 ] && break; prev=$n; sleep 5; done
curl -s "$E/api/v1/cards?limit=5000" > "$O/02_cards_before.json"
curl -s http://127.0.0.1:9200/genesis-cards/_count > "$O/02_opensearch_count_before.json"
log "engine serves $n cards before registration"

discover() {  # discover OUTFILE QUERY STRATEGY
  python3 -c 'import json,sys;print(json.dumps({"query":sys.argv[1],"limit":5,"strategy":sys.argv[2]}))' "$2" "$3" \
    | curl -s -X POST "$E/api/v1/discover" -H "$J" --data-binary @- > "$1"
}
Q1="unsupervised end-member extraction from geoscience mixtures"
discover "$O/03_search_before_hybrid.json" "$Q1" hybrid
take_shots before

log "register $(basename "$CARD") as data_card"
code=$(curl -s -o "$O/04_register_response.json" -w '%{http_code}' -X POST "$R/api/current/registry/data_card" \
  -H "Content-Type: text/vnd.genesis.data-card+markdown" --data-binary @"$CARD")
echo "$code" > "$O/04_register_http_code.txt"
log "registry answered HTTP $code: $(head -c 400 "$O/04_register_response.json")"

curl -s -X POST "$E/api/v1/admin/resync" > "$O/05_resync.json"
log "resync: $(cat "$O/05_resync.json")"
curl -s "$E/api/v1/cards/$CARD_ID" -o "$O/06_engine_card.json" -w '%{http_code}\n' > "$O/06_engine_card_http_code.txt"
REG_ID=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("id",""))' "$O/04_register_response.json" 2>/dev/null)
if [ -n "$REG_ID" ]; then
  curl -s "$R/api/current/registry/data_card/$REG_ID" -o "$O/07_registry_get.md" -w '%{http_code}\n' > "$O/07_registry_get_http_code.txt"
fi
curl -s "$E/api/v1/cards?limit=5000" > "$O/08_cards_after.json"
curl -s http://127.0.0.1:9200/genesis-cards/_count > "$O/08_opensearch_count_after.json"

for s in hybrid semantic graph; do discover "$O/09_search_after_$s.json" "$Q1" "$s"; done
discover "$O/10_q_panola.json" "stream water chemistry end-member mixing analysis Panola" hybrid
discover "$O/10_q_jasper.json" "hyperspectral unmixing benchmark Jasper Ridge" hybrid
discover "$O/10_q_archetypal.json" "archetypal analysis benchmark" hybrid
discover "$O/10_q_nazca.json" "marine sediment geochemistry Nazca Plate" hybrid
discover "$O/10_q_agenda.json" "when is the hackathon closing session" hybrid
take_shots after

{ curl -s -o /dev/null -w 'ui / %{http_code}\n' http://127.0.0.1:15173/
  curl -s -o /dev/null -w "ui /api/v1/cards/$CARD_ID %{http_code}\n" "http://127.0.0.1:15173/api/v1/cards/$CARD_ID"; } > "$O/11_ui_http_code.txt"
ps -u "$USER" -o rss=,args= | grep -E "s3mock|org.opensearch|uvicorn|nginx: master" | grep -v grep \
  | awk '{r=$1; $1=""; printf "%6.0f MB %s\n", r/1024, substr($0, 1, 110)}' > "$O/12_memory.txt"
du -sh "$W/sif" "$S/state" "$S/sbx" > "$O/12_disk.txt" 2>/dev/null

python3 - "$O" "$CARD_ID" > "$O/99_summary.txt" <<'PY'
import json, os, sys
o, cid = sys.argv[1], sys.argv[2]
def load(f):
    try: return json.load(open(os.path.join(o, f)))
    except Exception as e: return {"_error": str(e)}
def txt(f):
    try: return open(os.path.join(o, f)).read().strip()
    except Exception: return "?"
b, a = load("02_cards_before.json"), load("08_cards_after.json")
types = lambda cs: dict(sorted({c["card_type"]: sum(1 for x in cs if x["card_type"] == c["card_type"]) for c in cs}.items())) if isinstance(cs, list) else cs
print("cards before:", len(b) if isinstance(b, list) else b, types(b))
print("cards after: ", len(a) if isinstance(a, list) else a, types(a))
print("emma in before:", isinstance(b, list) and any(c["card_id"] == cid for c in b), " after:", isinstance(a, list) and any(c["card_id"] == cid for c in a))
print("register HTTP", txt("04_register_http_code.txt"), json.dumps(load("04_register_response.json"))[:400])
print("resync", json.dumps(load("05_resync.json")))
c = load("06_engine_card.json")
print("engine GET /cards/%s HTTP %s" % (cid, txt("06_engine_card_http_code.txt")),
      {k: c.get(k) for k in ("id", "title", "card_type", "sensitivity", "last_updated")} if "id" in c else c,
      "relationships:", len(c.get("relationships", [])) if isinstance(c, dict) else "")
print("registry GET HTTP", txt("07_registry_get_http_code.txt"))
for f in sorted(x for x in os.listdir(o) if x[:3] in ("03_", "09_", "10_")):
    d = load(f); rs = d.get("results", []) if isinstance(d, dict) else []
    print(f"{f}: total_found={d.get('total_found')} strategy={d.get('strategy_used')}")
    for r in rs[:5]: print(f"    {r.get('relevance_score', 0):.3f} {r.get('relevance_source')}  {r.get('card_id')}  {r.get('title', '')[:70]}")
    if not rs: print("   ", json.dumps(d)[:300])
PY
cat "$O/99_summary.txt"
log "hands-on done; results in $O"
