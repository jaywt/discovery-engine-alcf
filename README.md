# discovery-engine-alcf

The Genesis Mission Hackathon F4 hands-on (Discovery Engine + xCard Registry) run on an ALCF Polaris
compute node with unprivileged Apptainer, submitted through the ALCF IRI API, registering a data card
for the EMMA benchmark.

**Read the page:** https://jaywen.com/discovery-engine-alcf/ (source: [`index.md`](index.md)).

| Path | What |
|---|---|
| `scripts/` | `dle_up.sh` (bring-up, hands-on, teardown), `dle_lib.sh` (pinned images, env, nginx), `dle_handson.sh` (register and search), `iri_submit.py` (submit through IRI) |
| `card/` | the EMMA benchmark data card, xCard export, as registered |
| `runs/7754425/` | outputs and logs of the run on 2026-10-16, with the exact scripts that produced it |

The stack itself is [AI-ModCon/discovery-local](https://github.com/AI-ModCon/discovery-local); its images are pulled from ghcr.io, not redistributed here.
