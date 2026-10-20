---
title: The Genesis Discovery Engine on ALCF Polaris
---

# The Genesis Discovery Engine on ALCF Polaris

This page runs the hands-on from the Genesis Mission Hackathon session **F4: Discovery Engine and Machine-Actionable Cards (xCards)** (Argonne, 14–16 October 2026) on an ALCF Polaris compute node. Polaris has no Docker and no root access.

The worked example is a data card for the **EMMA benchmark** (unsupervised end-member extraction from geoscience mixtures). The card was registered with the xCard Registry and then found by the Discovery Engine's search.

**Result.** Job 7754425 ran on 16 October 2026 and took 149 seconds from start to teardown:

- All five services came up, and the bundled corpus was seeded.
- The EMMA card was registered (HTTP 201) and read back byte-identical.
- After registering, EMMA was the top hit for its own topic. Before registering, the top hit was an unrelated agent.

A second run, job 7762823 on 19 October, repeated this with two additions. It took [screenshots of the engine's web UI](#the-ui-screenshots) on the node itself, and it ran the whole stack in a private network namespace. Nothing in the stack was reachable from outside the namespace.

[Recipe](#the-recipe) · [Results](#results) · [Screenshots](#the-ui-screenshots) · [Run it yourself](#run-it-yourself) · [What it took](#what-it-took) · [Limits](#limits) · [The session](#the-f4-session-in-brief)

---

## The recipe

The session's stack is [AI-ModCon/discovery-local](https://github.com/AI-ModCon/discovery-local), a Docker Compose v2 file. Its images are public on ghcr.io.

On Polaris the same images, pinned by digest, run as **unprivileged Apptainer processes on one compute node**. They share the node's loopback interface, so each compose service name becomes `127.0.0.1` with its own port:

| Service | Image | Address on the node | Role |
|---|---|---|---|
| `s3` | `adobe/s3mock:3.12.0` | `127.0.0.1:9090`* | the registry's only storage |
| `opensearch` | `opensearch:2.17.1` | `127.0.0.1:9200` | BM25 + kNN hybrid index |
| `registry` | `ghcr.io/ai-modcon/xcard-registry` | `127.0.0.1:18100` | the xCard Registry (validates, versions, stores) |
| `seed` | the engine image | one-shot | pushes the bundled corpus through the registry |
| `api` | `ghcr.io/ai-modcon/genesis-discovery-api` | `127.0.0.1:18000` | the Discovery Engine |
| `ui` | `ghcr.io/ai-modcon/genesis-discovery-ui` | `127.0.0.1:15173` | the web UI (nginx) |

\*s3mock binds every interface, whatever it is told. Since run 7762823 the stack runs in a private network namespace whose only interface is loopback, so that is no longer reachable; see [Limits](#limits). The `registry-https` (Caddy) service was not ported: it only serves catalog links, and the catalog is off in the local stack.

The job is submitted through the **ALCF IRI API**, a REST interface to ALCF compute and storage, with a Globus token. No SSH session is involved.

The scripts:

- [`scripts/dle_up.sh`](https://github.com/jaywt/discovery-engine-alcf/blob/main/scripts/dle_up.sh) does everything that needs the network. It pulls the images, fetches the embedding model once and clones the repo. It then starts the stack in a private network namespace and checks from outside that nothing answers.
- [`scripts/dle_stack.sh`](https://github.com/jaywt/discovery-engine-alcf/blob/main/scripts/dle_stack.sh) brings the stack up in dependency order, runs the hands-on and the screenshots, and tears everything down.
- [`scripts/dle_handson.sh`](https://github.com/jaywt/discovery-engine-alcf/blob/main/scripts/dle_handson.sh): the session's register-and-find exercise as API calls, with every response saved.
- [`scripts/shots.py`](https://github.com/jaywt/discovery-engine-alcf/blob/main/scripts/shots.py): headless Chromium screenshots of the UI, from Microsoft's Playwright image.
- [`scripts/netns.py`](https://github.com/jaywt/discovery-engine-alcf/blob/main/scripts/netns.py) and [`scripts/nscheck.sh`](https://github.com/jaywt/discovery-engine-alcf/blob/main/scripts/nscheck.sh): the private network namespace, and the check it must pass before it is used.
- [`scripts/dle_lib.sh`](https://github.com/jaywt/discovery-engine-alcf/blob/main/scripts/dle_lib.sh): image digests, environment files translated from `compose.yaml`, the nginx config, and process helpers.

[`scripts/iri_submit.py`](https://github.com/jaywt/discovery-engine-alcf/blob/main/scripts/iri_submit.py) submits the job and reads results back, screenshots included.

## Results

From [run 7754425](https://github.com/jaywt/discovery-engine-alcf/tree/main/runs/7754425/), on node `x3009c0s19b0n0`, 2026-10-16 17:06–17:08 UTC:

| Step | Result |
|---|---|
| Pull 5 images (first time; cached after) | 75 s, 1.5 GB of SIF files |
| Stack ready (s3 → registry → seed → OpenSearch → engine → UI) | at 127 s |
| Seed the bundled corpus | 323 of 330 cards plus 2 hackathon documents. 5 were skipped because the registry has no framework or workflow type. 2 were rejected by the registry's validator (`LLNL_LPBF`, `morph_model-card`). |
| Engine corpus before | **324 cards**: 176 model, 127 agent, 18 infrastructure, 1 dataset, 2 hackathon materials |
| Register EMMA (`POST /api/current/registry/data_card`) | **HTTP 201**, id `5c5aeb72-…`, version 1 ([response](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7754425/out/04_register_response.json)) |
| Resync the engine (`POST /api/v1/admin/resync`) | 326 records loaded, 0 pruned; the engine now serves **325 cards** |
| Read back from the engine (`GET /api/v1/cards/emma-benchmark`) | HTTP 200, all 19 typed relationships ([card](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7754425/out/06_engine_card.json)) |
| Read back from the registry | byte-identical to the submitted file (sha256 `12a0dab1…613f`) |
| Memory (RSS) | about 2.3 GB: OpenSearch 1.17, s3mock 0.59, engine 0.43, registry 0.14 |

### Search, before and after

The query was *"unsupervised end-member extraction from geoscience mixtures"*:

| | Top hits |
|---|---|
| **Before** registering (hybrid) | PISCES Extraction Agent 0.735 · DAE-featured ET Prediction 0.589 · Subsurface Trend Analysis 0.500 · MIST Mixtures 0.500 · NDSR 0.402 |
| **After** (hybrid) | **EMMA Benchmark 1.000** |
| **After** (semantic) | **EMMA Benchmark 1.000** |
| **After** (graph) | no results: graph search walks typed relationships from a card and does not match free text |

The engine also returned the card for queries written from each dataset's side:

| Query | Top hit |
|---|---|
| stream water chemistry end-member mixing analysis Panola | EMMA 1.000 |
| hyperspectral unmixing benchmark Jasper Ridge | EMMA 1.000 (next: APOLLO 0.540) |
| marine sediment geochemistry Nazca Plate | EMMA 1.000 |
| archetypal analysis benchmark | EMMA 0.500, tied with an MLIR annotator |
| when is the hackathon closing session | the hackathon agenda 1.000 |

**How to read the scores.** The engine combines the lexical half (BM25) and the vector half (kNN) of its search, after min-max normalizing each half.

- **1.000** means the card was top in both halves.
- **About 0.5** means it was top in one half only.
- Before registration no card topped both halves, so the best score was 0.735.
- Two filters drop weak hits. A card that shares no word with the query needs at least 0.5, and any hit under 30% of the best score is dropped.
- After registration only EMMA survived for its own query.

The scores are not probabilities, and they are not comparable between queries.

### The card

[`card/emma-benchmark.xcard.md`](https://github.com/jaywt/discovery-engine-alcf/blob/main/card/emma-benchmark.xcard.md) is a Genesis data card that the [datacard-generator skill](https://github.com/jeanbez/datacard-generator-skill) (v2.1.0) generated in *provisional* mode. It was exported with the skill's `export_xcard.py` and reviewed by the dataset's authors before registration.

- Spine: `card_type: data`, `id: emma-benchmark`, `sensitivity: general`.
- It describes four datasets: a synthetic mixture set, Panola Mountain stream chemistry (905 samples), Nazca Plate sediment geochemistry (327 samples) and the Jasper Ridge hyperspectral scene.
- It carries 19 typed relationships to the source papers, archives and upstream data.

As the session advised, the registry accepts the *export* and rejects the full card ("profile markers are ambiguous").

## The UI screenshots

These come from [run 7762823](https://github.com/jaywt/discovery-engine-alcf/tree/main/runs/7762823/) on node `x3001c0s7b0n0`, 2026-10-20 02:17–02:19 UTC (19 October, US time).

- A headless Chromium on the compute node opened the UI at `127.0.0.1:15173`, inside the same private network namespace as the stack. No SSH tunnel or MFA was involved.
- The images were packed on the node and read back through IRI, checked by sha256.
- Every other number in this run matches run 7754425: the counts, HTTP codes and top hits. Two weaker hits moved by 0.001–0.002, and the EMMA/MLIR tie at 0.500 listed in the other order.

**Redactions.** The bundled corpus is other teams' work, and it was published without a license. So these images show only what the run record already shows for it: titles, types and scores.

- Every other card's description, tags and I/O modes are covered by grey bars before the screenshot is taken.
- When other cards are on screen, the facet lists (tags, data modes) are covered too, because they are pooled from those cards.
- The EMMA card is shown in full.

**Tile scores.** The UI's search fetches up to 100 results per query, against the 5 that `dle_handson.sh` asks for. That is why the counts here are higher than in the [search tables](#search-before-and-after). A tile's percentage is its relevance score, and the UI shows none for a score of 1.0.

### Before registering

[![The Explore view, before registering: 324 cards](https://github.com/jaywt/discovery-engine-alcf/raw/main/runs/7762823/shots/03_explore_corpus.png)](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/shots/03_explore_corpus.png)

*Explore, the corpus as seeded: 324 cards (176 model, 127 agent, 18 infrastructure, 2 hackathon materials, 1 dataset).*

[![The EMMA query before registering: PISCES Extraction Agent on top](https://github.com/jaywt/discovery-engine-alcf/raw/main/runs/7762823/shots/04_search_before.png)](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/shots/04_search_before.png)

*"unsupervised end-member extraction from geoscience mixtures", hybrid. The top hit is PISCES Extraction Agent (85%), and there is no EMMA card yet.*

### After registering and resyncing

[![The same query after registering: EMMA Benchmark on top](https://github.com/jaywt/discovery-engine-alcf/raw/main/runs/7762823/shots/05_search_after.png)](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/shots/05_search_after.png)

*The same query: EMMA Benchmark is first, with no percentage (a score of 1.0). The next hit is at 42%.*

[![The EMMA card's detail panel](https://github.com/jaywt/discovery-engine-alcf/raw/main/runs/7762823/shots/06_card_detail.png)](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/shots/06_card_detail.png)

*The card's detail panel, as the engine parsed it from the registry: spine, contact, provider (Codabench), version 0.1.0, sensitivity, MIT license, I/O contract. The contact role reads "ROR"; see [Limits](#limits).*

[![The EMMA card's relationships](https://github.com/jaywt/discovery-engine-alcf/raw/main/runs/7762823/shots/07_card_relationships.png)](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/shots/07_card_relationships.png)

*The card's typed relationships to its source papers and data, starting with the references.*

[![The EMMA card's raw view](https://github.com/jaywt/discovery-engine-alcf/raw/main/runs/7762823/shots/08_card_raw.png)](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/shots/08_card_raw.png)

*Raw: the export as the registry stored it, byte-identical to [the submitted file](https://github.com/jaywt/discovery-engine-alcf/blob/main/card/emma-benchmark.xcard.md).*

| | |
|---|---|
| [![Jasper Ridge query](https://github.com/jaywt/discovery-engine-alcf/raw/main/runs/7762823/shots/09_search_jasper.png)](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/shots/09_search_jasper.png) | [![Panola query](https://github.com/jaywt/discovery-engine-alcf/raw/main/runs/7762823/shots/10_search_panola.png)](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/shots/10_search_panola.png) |
| *"hyperspectral unmixing benchmark Jasper Ridge": EMMA first, then APOLLO at 58%.* | *"stream water chemistry end-member mixing analysis Panola": EMMA first, then 30 weaker hits.* |
| [![The workflow canvas's resource palette](https://github.com/jaywt/discovery-engine-alcf/raw/main/runs/7762823/shots/11_workspace_palette.png)](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/shots/11_workspace_palette.png) | [![Create a Card](https://github.com/jaywt/discovery-engine-alcf/raw/main/runs/7762823/shots/12_create_card.png)](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/shots/12_create_card.png) |
| *Workspace, "+ Add resource" (Ctrl-K), searching "end-member extraction". The card is one click from the workflow canvas.* | *Create a Card, the UI's own card builder.* |

[![Settings, opened on first load](https://github.com/jaywt/discovery-engine-alcf/raw/main/runs/7762823/shots/01_settings_no_llm.png)](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/shots/01_settings_no_llm.png)

*On first load the UI opens Settings to ask for an LLM key (Model Access Gateway or Anthropic). None was set; search and browse work without one.*

## Run it yourself

You need an ALCF account on a project with Polaris time, and an ALCF IRI access token from a Globus login. The token goes in an environment variable; nothing here stores it.

```bash
git clone https://github.com/jaywt/discovery-engine-alcf && cd discovery-engine-alcf
export IRI_TOKEN_ALCF=...  ALCF_USER=you  ALCF_PROJECT=YourProject
uv run --with httpx scripts/iri_submit.py submit scripts/ card/emma-benchmark.xcard.md \
    --card-id emma-benchmark --queue debug --minutes 30
uv run --with httpx scripts/iri_submit.py status <job-id>
uv run --with httpx scripts/iri_submit.py view /home/you/discovery-local/runs/<job>/out/99_summary.txt
```

To register your own card, pass its `.xcard.md` export and its spine `id`. Results land in `~/discovery-local/runs/<job>/out/`: one numbered file per step, plus a `99_summary.txt`. The screenshots are in `out/shots/`. To read them back through IRI:

```bash
uv run --with httpx scripts/iri_submit.py fetch /home/you/discovery-local/runs/<job>/shots.tgz.b64 shots.tgz
```

The first run also pulls the Playwright image (about 0.7 GB) and installs the matching `playwright` package. `--no-shots` skips both.

This exact sequence, from a fresh checkout, was run as job 7762868 on 19 October (another node, the same results, 123 s).

From a Polaris login node the scripts also run without IRI, as a PBS job:

```bash
qsub -A YourProject -q debug -l select=1 -l walltime=0:30:00 -l filesystems=home:eagle \
     -v CARD=$PWD/card/emma-benchmark.xcard.md,CARD_ID=emma-benchmark scripts/dle_up.sh
```

**To use the UI yourself**, submit with `--hold 60` (or `HOLD_MIN=60`) to keep the stack up for an hour after the hands-on. A held stack runs on the host loopback, not in the private namespace, because the tunnel has to reach it. Then tunnel from your laptop, which prompts for ALCF MFA:

```bash
ssh -J you@polaris.alcf.anl.gov -L 15173:127.0.0.1:15173 -L 18000:127.0.0.1:18000 \
    -L 18100:127.0.0.1:18100 you@<compute-node>   # the node name is in runs/<job>/NODE
```

Then open <http://localhost:15173> for the UI, `localhost:18000/docs` for the engine API and `localhost:18100/api/current/docs` for the registry API.

## What it took

Each item below is something the Docker version gets for free, with the workaround used on Polaris:

- **No Docker and no root.** Apptainer 1.4.1 (`module load spack-pe-base apptainer`) runs the OCI images unprivileged. It shares the host network, so there is no compose DNS: `s3`, `registry`, `api` and `opensearch` became `127.0.0.1` in every environment file.
- **OpenSearch and `vm.max_map_count`.** The node has 65530, and OpenSearch's bootstrap check wants 262144. That can't be changed without root.
  - `-Enode.store.allow_mmap=false` sidesteps the check, with `discovery.type=single-node` and `bootstrap.memory_lock=false`.
  - The image's files are owned by uid 1000, so OpenSearch runs from an unprivileged `apptainer build --sandbox` copy with a writable config directory.
- **Docker Hub rate limits.** ALCF's outbound proxy is one shared address, so anonymous Docker Hub pulls hit the limit easily. OpenSearch comes from `public.ecr.aws` instead; it is the same digest.
- **Port 80.** The UI image's nginx listens on :80, which needs root. A replacement config listens on `127.0.0.1:15173` and proxies `/api/` to the engine. Its pid, temp and log paths are on scratch.
- **TLS bypasses.** The compose file sets `NODE_TLS_REJECT_UNAUTHORIZED=0` and `PYTHONHTTPSVERIFY=0` for the ORNL venue's TLS-inspecting proxy. They are left out here, because ALCF's proxy does not re-sign TLS.
- **IRI quirks.**
  - File upload and download both returned `501 not implemented`. `view` returns text and garbles binary data, so the screenshots are packed as base64 on the node and paged back through `view`.
  - A multi-line script passed as `bash -lc` arrived empty.
  - The fix: the scripts and card travel as one gzip+base64 tar inside a single-line command. The node checks each file with `sha256sum -c` before running anything.
  - The IRI compute API answered only for Polaris, not Sophia.
- **An open port.** s3mock binds every interface whatever it is told. An unprivileged user namespace that maps our own uid can own a new network namespace. Within that, `lo` can be brought up with no root and no setuid helper; [`netns.py`](https://github.com/jaywt/discovery-engine-alcf/blob/main/scripts/netns.py) does it in 25 lines of Python. Inside, the only interface is loopback and there is no route out.
  - So `dle_up.sh` does all its downloading first.
  - The engine's embedding model is fetched once into a cache and loaded with `HF_HUB_OFFLINE=1`. Before, it was downloaded from Hugging Face on every start.
  - In run 7762823, all six ports answered nothing from the host, on loopback and on both node addresses ([`13_exposure.txt`](https://github.com/jaywt/discovery-engine-alcf/blob/main/runs/7762823/out/13_exposure.txt)).
- **Screenshots without a browser on the node.** Microsoft's Playwright image ships Chromium but not the Python package (its build deletes it). The matching `playwright==1.48.0` is installed once into a persistent directory and put on `PYTHONPATH`.
- **Queues.** During the event, the hackathon reservation queue started jobs within a minute, while `debug` waited more than an hour. That reservation is gone now; `debug` allows one queued job per user.

## Limits

- **s3mock listens on all interfaces.** It is the registry's storage, with dummy credentials and no access control. Its Jetty connector ignores `--server.address`; [S3Mock 3.12.0](https://github.com/adobe/S3Mock/blob/3.12.0/server/src/main/java/com/adobe/testing/s3mock/S3MockConfiguration.java) builds it with no host.
  - **Fixed since run 7762823** by the private network namespace (see [What it took](#what-it-took)).
  - It is still open in two cases: in run 7754425, where port 9090 was reachable from Polaris's internal network for about a minute, with only public data in it; and in any run held open for a tunnel (`--hold`), which needs the host loopback.
  - If the namespace check fails on a node, `dle_up.sh` says so and falls back to the host loopback. The mode used is recorded in `runs/<job>/NETWORK`.
- **The registry is temporary.** Its state lives on node-local scratch and is wiped when the job ends. Registering here does not publish anything, and the id above exists only inside that run. A shared registry is a separate step: the session asked for cards on public datasets to be shared with the F4 team.
- **The screenshots are scripted.** They show the views a fixed script reached. Nobody clicked through the UI, and the workflow canvas, assistant and card builder were not exercised beyond their first screen.
- **No LLM features.** The workflow assistant needs an AmSC Model Access Gateway token, and it was not used. Search, browse, the card graph, the registry API and registration work without it.
- **A parsing nit.** The engine's contact parser read the role from the card's affiliation link and shows "ROR". The card itself is correct.
- The corpus counts differ slightly from the session slides (328 cards). These counts are what the engine reported.

## The F4 session in brief

The F4 session was presented by Rafael Ferreira da Silva (ORNL), Diana McSpadden (JLab) and Anna Giannakou (LBNL). Its slides are in the hackathon's Box folder under Foundations.

- **The Discovery Engine** is the scientist's entry point to the Genesis Mission Platform. Every answer is grounded in a catalog of **xCards**: machine-actionable cards describing models, agents, datasets and infrastructure.
  - **Discover**: hybrid BM25 and kNN search over local `bge-small` embeddings, with facets and a relevance floor.
  - **Compose**: a workflow canvas that checks each step against its card's I/O contract.
  - **Reason**: a grounded assistant and a hypothesis critic.
  - Each card is ingested three ways: a semantic index (description), a knowledge graph (typed relationships) and a capability registry (I/O contracts).
- **An xCard** combines YAML front matter, which is machine-validated, with a Markdown narrative.
  - Every card has a common spine (`card_type`, `id`, `sensitivity`, `io_contract`, `relationships`) plus one type extension.
  - Data cards embed the Genesis data card v2.0.0. It has six FAIR-aligned facets, of which discoverability and accessibility are required.
- **The hands-on**: run the six-container stack locally, register a card with `POST /api/current/registry/<type>_card`, resync the engine, and find the card in search.
  - Plain v2.0.0 data cards fail the local registry because they lack the spine. Use the datacard-generator skill in provisional mode and submit its `.xcard.md` export.

References:
- Data card schema, template and tools: [doi:10.18141/3376151](https://doi.org/10.18141/3376151)
- Technical report: [doi:10.2172/3377514](https://doi.org/10.2172/3377514)
- Skills: [AI-ModCon/genesis-skills](https://github.com/AI-ModCon/genesis-skills) and [jeanbez/datacard-generator-skill](https://github.com/jeanbez/datacard-generator-skill)

---

### About this page

- Run by Tao Wen (Syracuse University) on ALCF Polaris under the GenesisHackathonOct26 allocation.
- Stack: discovery-local @ [`f88a609`](https://github.com/AI-ModCon/discovery-local/commit/f88a6097f3cddca84aa57d6f44edd0b5d5039ab1), with images pinned by digest in [`dle_lib.sh`](https://github.com/jaywt/discovery-engine-alcf/blob/main/scripts/dle_lib.sh).
- The scripts that produced each run are kept byte-for-byte in [`runs/7754425/scripts/`](https://github.com/jaywt/discovery-engine-alcf/tree/main/runs/7754425/scripts/) and [`runs/7762823/scripts/`](https://github.com/jaywt/discovery-engine-alcf/tree/main/runs/7762823/scripts/), each with its `SHA256SUMS`. [`scripts/`](https://github.com/jaywt/discovery-engine-alcf/tree/main/scripts/) is the 7762823 set.
- Published run outputs are trimmed to identifiers and scores, and the screenshots are redacted to match. The engine's full listings include other teams' cards from the corpus, which carries no license.

