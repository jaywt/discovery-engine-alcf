---
xCard:
  card_type: data
  version: 2.1.0
id: emma-benchmark
name: 'EMMA Benchmark: unsupervised end-member extraction from geoscience mixtures'
description: 'A benchmark for unsupervised end-member extraction (end-member mixing analysis, EMMA): given only a sample matrix and the number of end-members p, a method must recover the pure end-members and, for synthetic data, each sample''s mixing proportions. It packages nine datasets from Wang & Wen (2025), six synthetic sets with exact answers plus Panola stream chemistry, Nazca Plate sediment geochemistry and the Jasper Ridge hyperspectral image, with reference end-members, saved baseline outputs and SHA-256 provenance.'
science:
- Geosciences
- Environmental Sciences
- Mathematics and Computing
keywords:
- end-member mixing analysis
- archetypal analysis
- blind source separation
- hyperspectral unmixing
- geochemistry
- hydrology
- benchmark
- SPGD-AA
sensitivity: general
developed_by:
- Zanchenling Wang
- Tao Wen
last_updated: '2026-10-16'
version: 0.1.0
persistent_id: emma-benchmark-0.1.0
provider:
  organization: Codabench
  url: https://www.codabench.org/competitions/18387/
license:
  spdx_id: MIT
  name: MIT License
  url: https://opensource.org/licenses/MIT
governance:
  export_control_status: 'No'
  privacy_pii: 'No'
  privacy_phi: 'No'
  review_provenance:
  - source_review_reference: 'internal_qa: docs/VALIDATION.md'
    review_purpose: Data provenance, reproduction and metric validation
    source_review_authority: Benchmark authors (self-review)
    review_date: '2026-10-15'
    comments: Internal checks only; no institutional, export-control or IRB review was performed or needed for these public, non-human-subject data.
relationships:
- type: references
  target: https://doi.org/10.1029/2024JH000540
  target_label: publication (is_described_by)
- type: references
  target: https://doi.org/10.1016/0022-1694(90)90131-G
  target_label: publication (references)
- type: references
  target: https://doi.org/10.1016/0022-1694(90)90130-P
  target_label: publication (references)
- type: references
  target: https://doi.org/10.1029/92WR00706
  target_label: publication (references)
- type: references
  target: https://doi.org/10.1002/hyp.255
  target_label: publication (references)
- type: references
  target: https://doi.org/10.5194/hess-26-1977-2022
  target_label: publication (references)
- type: references
  target: https://doi.org/10.1130/MEM154-p133
  target_label: publication (references)
- type: references
  target: https://doi.org/10.1016/0016-7037(84)90348-X
  target_label: publication (references)
- type: references
  target: https://arxiv.org/abs/1708.05125
  target_label: publication (references)
- type: references
  target: https://doi.org/10.1016/j.isprsjprs.2013.11.014
  target_label: publication (references)
- type: references
  target: https://doi.org/10.5194/hess-25-3397-2021
  target_label: publication (references)
- type: references
  target: https://doi.org/10.1109/TIP.2023.3301769
  target_label: publication (references)
- type: references
  target: https://arxiv.org/abs/2511.05614
  target_label: publication (references)
- type: derived_from
  target: https://doi.org/10.5281/zenodo.15178390
  target_label: 'endmembers: data and results for SPGD-AA (is_derived_from)'
- type: derived_from
  target: https://doi.org/10.1002/ggge.20247
  target_label: Nazca sediment geochemistry (Pisias et al. 2013 SI) (is_derived_from)
- type: derived_from
  target: https://github.com/Estherrrrrxu/CHEMMA
  target_label: Panola stream chemistry (CHEMMA repository) (is_derived_from)
- type: derived_from
  target: https://huggingface.co/datasets/danaroth/jasper_ridge
  target_label: Jasper Ridge hyperspectral image (is_derived_from)
- type: references
  target: https://doi.org/10.5281/zenodo.15198941
  target_label: archetypes (SPGD-AA reference solution) (analyzes)
- type: references
  target: emma-bench-0.1.0
  target_label: emma-bench (loaders, scoring, leaderboard, Codabench bundle) (analyzes)
io_contract:
  input_modes: []
  output_modes:
  - text/csv
  - application/x-xlsx
  - application/x-envi
  - application/x-mat
  - application/json
  - application/x-markdown
  modalities:
  - tabular
  - image
  task_tags:
  - unsupervised learning
  - end-member extraction
  - blind source separation
  - hyperspectral unmixing
  dataset_role: final
extension:
  formats:
  - csv
  - xlsx
  - envi
  - mat
  - json
  - markdown
  schema_fields:
  - name: sample_id
    description: 'Row identifier assigned by the benchmark loaders: s0000... (synthetic, row order), p000... (Panola, row order), n<Sample No> (Nazca), L<line>S<sample> (Jasper Ridge).'
    data_type: string
    unit: not_applicable
  - name: A, B, C, D, E, F, G, H
    description: Eight synthetic features of the six synthetic_* datasets; each sample is a convex mixture of 4 end-members (EM1-EM4).
    data_type: float
    unit: arbitrary units
    range: noise-free and alpha sets 0.116-1.287; noisy 0.0-1.469; shifted 10.158-11.167
  - name: EM1, EM2, EM3, EM4
    description: Synthetic mixing proportions (ground truth only, not a model input); each row sums to 1.
    data_type: float
    unit: fraction
    range: 0-1
  - name: Alk
    description: Panola stream-water alkalinity.
    data_type: float
    unit: µeq/L
    range: -6.0 to 363.1
  - name: SO4
    description: Panola stream-water sulfate.
    data_type: float
    unit: µeq/L
    range: 1.70-224.0
  - name: Na
    description: Panola stream-water sodium.
    data_type: float
    unit: µeq/L
    range: 25.2-261.3
  - name: Mg
    description: Panola stream-water magnesium.
    data_type: float
    unit: µeq/L
    range: 27.2-107.0
  - name: Ca
    description: Panola stream-water calcium.
    data_type: float
    unit: µeq/L
    range: 35.9-199.0
  - name: Si
    description: Panola stream-water dissolved silica.
    data_type: float
    unit: µmol/L
    range: 42.7-472.5
  - name: Al, Si, Mn, Fe, Cu, Ni, Zn, Ba (ppm)
    description: Nazca Plate surface-sediment element concentrations on a carbonate-free basis (Pisias et al. 2013 SI, columns A:I with Sample No). The benchmark input divides each row by its 8-element sum (following Leinen & Pisias 1984).
    data_type: float
    unit: ppm in the source file; weight fraction of the 8 elements as benchmark input
    range: 'ppm: Al 2019-92239, Si 32135-331261, Mn 2664-205239, Fe 16785-370631, Cu 52-1981, Ni 97-2464, Zn 114-1474, Ba 211-70496; fraction 0.00012-0.830'
  - name: b001-b198
    description: Jasper Ridge reflectance in 198 bands (399.4-2457.2 nm) for 100 x 100 pixels; ENVI BIL int16 divided by 10,000.
    data_type: float
    unit: reflectance
    range: -0.0448 to 0.5437 (0.81% of values are small negatives, kept as is)
  - name: endmember
    description: 'Row label in reference end-member files: EM1-EM4 (synthetic); Organic, Hillslope, Groundwater (Panola); Detrital, Hydrothermal, Biogenic, Authigenic, Dissolution Residue (Nazca); Tree, Water, Soil, Road (Jasper Ridge).'
    data_type: string
    unit: not_applicable
  ai_usage:
    training_use_status: Conditional
    training_use_conditions: Permitted by the MIT license. For benchmark results, only the dev-phase datasets may be used for development; test-phase datasets and every ground-truth file must not be used for training or tuning, and outside-data augmentation is not allowed.
    inference_use_status: 'Yes'
    evaluation_use_status: 'Yes'
    restrictions: A method's only valid input is a dataset's X plus p. It must not read ground-truth end-member files, mixing_proportions files, end4.mat, the *_ratio.csv or LP1984_* files, xufei2022_endmembers.csv or data/saved_results/. SUBMISSION.md asks for a declaration.
    bias_risks: 'Small, domain-specific coverage: three real datasets (one watershed, one ocean plate, one hyperspectral scene) and synthetic data with 4 end-members x 8 features. Synthetic test sets reuse the dev end-members. Literature reference end-members can favour methods that agree with prior interpretations.'
    safety_considerations: No known safety risks; the data are public, non-sensitive environmental measurements and synthetic mixtures.
    human_review_required: 'Yes'
---
> Registry export of `genesis_datacard_emma_benchmark_unsupervised_end_member_extraction_from_geoscience_mixtures.md`, generated by export_xcard.py. The full Genesis datacard is the authoritative record; regenerate this file rather than editing it.

datacard:
  id:
    value: emma-benchmark
  datacard_version: 1.0.0
identification:
  name: 'EMMA Benchmark: unsupervised end-member extraction from geoscience mixtures'
  version: 0.1.0
description:
  summary: 'A benchmark for unsupervised end-member extraction (end-member mixing analysis, EMMA): given only a sample matrix and the number of end-members p, a method must recover the pure end-members and, for synthetic data, each sample''s mixing proportions. It packages nine datasets from Wang & Wen (2025), six synthetic sets with exact answers plus Panola stream chemistry, Nazca Plate sediment geochemistry and the Jasper Ridge hyperspectral image, with reference end-members, saved baseline outputs and SHA-256 provenance.'
categorization:
  tags:
    project: Genesis Mission Hackathon
    science: Geosciences
    risk: general
  task_category:
  - unsupervised learning
  task_subcategory:
  - end-member extraction
  - blind source separation
  - hyperspectral unmixing
license:
  spdx_id: MIT
  name: MIT License
  url: https://opensource.org/licenses/MIT
dataset_info:
  data_formats:
  - csv
  - xlsx
  - envi
  - mat
  - json
  - markdown
  modalities:
  - tabular
  - image
---

# Datacard for EMMA Benchmark: unsupervised end-member extraction from geoscience mixtures

**Last Updated**: 2026-10-16

### Machine Usability Snapshot

| Intended Capability | DataCard Support |
| ------ | ------ |
| Discoverability | Yes |
| Accessibility | Yes |
| Interoperability | Yes |
| Reusability | Yes |
| Governed Use | Yes |
| AI Usability | Yes |
| License Clarity | Yes |
| Checksum / Fixity | Yes |
| Semantic Context | Yes |

Readiness: all six capability flags are set, which the skill's heuristic places at level 3 (AI-ready and trustworthy). This is a narrative label only. It has no YAML field and has not been reviewed independently.

# ---- Discoverable ----

## Description

### Dataset Description
The EMMA Benchmark tests unsupervised end-member extraction, also called end-member mixing analysis (EMMA). A method gets only a sample matrix X and the number of end-members p. It must recover the pure end-members and, for the synthetic data, each sample's mixing proportions.

The benchmark packages nine datasets from Wang & Wen (2025):
- six synthetic sets with exact answers;
- Panola stream chemistry;
- Nazca Plate sediment geochemistry;
- the Jasper Ridge hyperspectral image.

It also includes reference end-members, saved baseline outputs and SHA-256 provenance for every file.

### Domain and Purpose
Science domains are "Geosciences", "Environmental Sciences" and "Mathematics and Computing". The sub-topics are end-member mixing analysis, geochemistry, hydrology and hyperspectral unmixing.

The purpose is to measure, with one fixed protocol, how well unsupervised methods recover the sources of linear geoscience mixtures. Methods in scope include archetypal analysis, NMF, clustering and unmixing. The comparison spans hydrology, marine geochemistry and remote sensing. It includes regimes with few near-pure samples and regimes with shifted features.

## Keywords
end-member mixing analysis, archetypal analysis, blind source separation, hyperspectral unmixing, geochemistry, hydrology, benchmark, SPGD-AA

## Sensitivity

### Security / Marking Considerations
- Overall sensitivity: `Public`. Classification: `No`. CUI: `No`. UCNI: `No`. Marking scheme: `None`.
- The card itself is also `Public`.
- The registry spine projects this to `categorization.tags.risk: general`.

## Context and Provenance

### Resources used, including funding and facilities, to create the dataset
- **Funding:** the U.S. National Science Foundation ([ROR 021nxhr62](https://ror.org/021nxhr62)), award **OAC-2209864** to Tao Wen.
  - The award is "Collaborative Research: Frameworks: DeCODER" from the Office of Advanced Cyberinfrastructure, running 2022-10-01 to 2026-12-31.
  - This is the award the paper acknowledges. The benchmark packaging may not have been funded by it.
- **Research organization:** Syracuse University ([ROR 025r5qe02](https://ror.org/025r5qe02)).
- **Computing:** one node of the ALCF Polaris supercomputer ([ROR 01svjdw65](https://ror.org/01svjdw65)) produced the committed reference results on 2026-10-15.
- No DOE program office sponsored this dataset.

### Developed by
- **Zanchenling Wang** ([0000-0003-4117-5221](https://orcid.org/0000-0003-4117-5221)), Syracuse University ([ROR](https://ror.org/025r5qe02)).
  - CRediT roles: Conceptualization, Data curation, Formal analysis, Investigation, Methodology, Software, Validation, Visualization, Writing (original draft), Writing (review & editing).
- **Tao Wen** ([0000-0002-6113-7532](https://orcid.org/0000-0002-6113-7532)), Syracuse University ([ROR](https://ror.org/025r5qe02)), twen08@syr.edu.
  - CRediT roles: Conceptualization, Funding acquisition, Project administration, Supervision, Writing (review & editing).

The roles come from the paper's author-contribution statement. The affiliations are the ones given in the paper.

### Contributed by
No other contributors are recorded for the benchmark package.
- The archetypes package (Aleix Alcacer and Zanchenling Wang) is listed under Related software.
- The third-party data sources are listed under Related datasets.

## Methods

### Dataset generation, collection, and procedures
The dataset is derived from prior datasets: the SPGD-AA paper's data release, [WEN-Research-Group/endmembers@76fcca1](https://github.com/WEN-Research-Group/endmembers/tree/76fcca1e79e4df38ce9841950292285b17415455) (Zenodo [10.5281/zenodo.15178390](https://doi.org/10.5281/zenodo.15178390)).

**Synthetic data.** The data come from upstream `scripts/data/generate_synthetic_data.py`.
- There are 4 end-members × 8 features (A–H).
- The 1000 proportion vectors are drawn from Dirichlet(α = 1, seed 42), with α = 2 and α = 4 variants that give fewer near-pure samples.
- The noisy set adds Gaussian noise (σ = 0.1) to both the end-members and the samples, then clips at 0.
- The shifted sets add +10 to every feature. This breaks methods that rely on non-negativity, such as NMF.

**Real data.** All three sets are redistributed unchanged. The descriptions follow paper Sec. 2.4.
- **Panola stream chemistry.**
  - **Site:** Panola Mountain Research Watershed, Georgia, USA. It is a 41-ha forested catchment on granodiorite with old, highly weathered soil, in a warm temperate subtropical climate.
  - **Samples:** six solutes in 905 stream-water samples collected **1985-10-01 to 1988-09-30** (Hooper et al. 1990; Hooper 2001). The file was retrieved from the CHEMMA repository.
  - **Reference end-members:** the medians of field soil-solution samples in Hooper et al. (1990), Table 3. They are organic horizon, hillslope and groundwater, and they match SI Table S4 exactly.
  - **Related network:** CUAHSI HIS lists the site at <https://hiscentral.cuahsi.org/pub_network.aspx?n=385>.
- **Nazca Plate surface-sediment geochemistry.**
  - **Samples:** eight elements in 327 deep-sea surface sediments from the southeastern Pacific, on a carbonate-free basis. They come from the Pisias et al. (2013) supporting information, which also lists sample latitude and longitude.
  - **Reference end-members:** Dymond (1981), from linear programming (SI Table S5).
    - The hydrothermal end-member was derived from samples near the East Pacific Rise crest.
    - The dissolution residue was based on domain knowledge.
    - The others were taken from literature.
- **Jasper Ridge hyperspectral image.**
  - **Image:** a 100 × 100 pixel scene of the Jasper Ridge Biological Preserve, California, USA, from the **AVIRIS** sensor.
  - **Bands:** originally 224 bands over 380–2500 nm. The 26 bands affected by water vapor and atmospheric interference were removed, leaving 198. The file is from Hugging Face `danaroth/jasper_ridge`.
  - **Reference end-members:** in `end4.mat` (Zhu 2017). They are pure pixels matched to spectral-library spectra (Zhu 2017; Zhu et al. 2014).

**Baselines.** Per the SI Table S2 footnote, the saved baselines were produced as follows:
- **NMF** follows Shaughnessy et al. (2021) without rescaling.
  - It uses 3,000 random starts and filters out proportions outside 0.9–1.1.
  - End-members are ranked by rule: EM1 has the largest A, EM2 the largest D, EM4 the largest H, and EM3 is the rest. Runs that cannot be ranked are discarded.
- **EDAA** uses the [inria-thoth code](https://github.com/inria-thoth/EDAA) with default parameters.
- **CHEMMA** follows Xu Fei & Harman (2022).

**Processing.** See Data Processing below.

---

# ---- Accessible ----

## Sharing & Access
Access level: **Open**, for public partners. Use is governed by the MIT license; cite Wang & Wen (2025) and the original Panola, Nazca and Jasper Ridge sources.

- **Landing page:** the Codabench competition <https://www.codabench.org/competitions/18387/>, published 2026-10-16.
  - Its bundle carries the public inputs for all nine datasets.
  - Its metadata can be read without authentication at `https://www.codabench.org/api/competitions/18387/`.
- **Full package:** the v0.1.0 package (`data/raw/`, 26 files, and `data/saved_results/`, 21 files) is not yet on a public git host.
- **Re-download:** every raw file can be fetched again from the pinned upstream commit with `scripts/fetch_data.py --download`.
- **Archive:** the paper's Zenodo archive [10.5281/zenodo.15178390](https://doi.org/10.5281/zenodo.15178390) (v0.0.0-alpha, 2025-04-08) holds byte-identical copies of all 26 raw files and the 20 saved-result CSVs.
- **Contact:** Tao Wen (twen08@syr.edu).

---

# ---- Interoperable ----

## Data Structure

### Files & Structure
**Size.** The dataset holds 17,232 samples across nine datasets in 49 files, totalling 5,514,151 bytes uncompressed and 3,863,454 bytes as a gzipped tar. The data are tabular, plus one hyperspectral image.

**Layout.**
- `data/raw/<synthetic|panola|nazca|jasper_ridge>/` holds the inputs and the reference end-members.
- `data/raw/MANIFEST.json` holds the SHA-256, size and upstream URL of every raw file.
- `data/saved_results/synthetic/` holds the published NMF, CHEMMA and EDAA outputs.
- `data/SCHEMA.md` documents every file, field, ID rule and unit.

| Dataset | Phase | Samples × features | p | Input (X) | Reference end-members |
|---|---|---|---|---|---|
| synthetic_noisefree | dev | 1000 × 8 | 4 | `synthetic/noisefree_samples.csv` | `synthetic/endmembers.csv` (exact) |
| synthetic_noisy | dev | 1000 × 8 | 4 | `synthetic/noisy_samples.csv` | `synthetic/endmembers.csv` (exact) |
| synthetic_alpha2 / alpha4 | test | 1000 × 8 | 4 | `synthetic/alpha=2_samples.csv`, `alpha=4_samples.csv` | `synthetic/endmembers.csv` (exact) |
| synthetic_alpha2_shifted / alpha4_shifted | test | 1000 × 8 | 4 | `synthetic/alpha=*_shifted_samples.csv` | `synthetic/endmembers_shifted.csv` (exact, +10) |
| panola | test | 905 × 6 | 3 | `panola/panola_data.csv` | `panola/panola_end_members.csv` (Hooper 1990 medians) |
| nazca | test | 327 × 8 | 5 | `nazca/ggge20247-sup-001a-supinfo1a.xlsx` (A:I, row-normalized) | `nazca/Dymond1981_endmember_fraction.csv` |
| jasper_ridge | test | 10,000 × 198 | 4 | `jasper_ridge/jasperRidge2_R198.{hdr,img}` | `jasper_ridge/end4.mat` field `M` |

**Splits.** There are no train/test splits, because nothing is trained. The phases above group the datasets instead.

### Specialized formats or other abbreviations used
- **CSV:** comma-separated values, UTF-8, with a header row.
- **XLSX:** Office Open XML workbook (the Nazca source table).
- **ENVI:** a `.hdr` text header with a `.img` binary file.
  - Band-interleaved-by-line, int16, little-endian, reflectance scale factor 10,000.
  - 100 lines × 100 samples × 198 bands, 399.4–2457.2 nm.
- **MAT:** MATLAB 5.0 MAT-file. `end4.mat` holds `M` (198 × 4 end-members), `A` (abundances) and `cood` (labels).
- **JSON:** `MANIFEST.json`.
- **Markdown:** README and schema files.
- **Abbreviations:**
  - EMMA: end-member mixing analysis.
  - SPGD-AA: simplex projected gradient descent archetypal analysis.
  - p: number of end-members.
  - Alk: alkalinity.

## Related Resources

### Related datasets, standards, metadata, and ontologies
All four sources are related by `is_derived_from`:
- **endmembers: data and results for SPGD-AA,** DOI [10.5281/zenodo.15178390](https://doi.org/10.5281/zenodo.15178390). All 26 raw files are copied byte-for-byte from commit 76fcca1.
- **Nazca sediment geochemistry** (Pisias et al. 2013 SI), DOI [10.1002/ggge.20247](https://doi.org/10.1002/ggge.20247).
- **Panola stream chemistry,** via <https://github.com/Estherrrrrxu/CHEMMA>.
- **Jasper Ridge hyperspectral image,** via <https://huggingface.co/datasets/danaroth/jasper_ridge>.

**Other sources.** Hooper (2001) and Christophersen et al. (1990) describe the Panola site and its mixing model. The CUAHSI HIS network page for Panola is <https://hiscentral.cuahsi.org/pub_network.aspx?n=385>.

**Standards.** The benchmark's corpus entry (`mlcommons_corpus_entry.yaml`) follows the MLCommons Science Benchmarks Ontology (arXiv:2511.05614).

### Related publications
- **`is_described_by`:** Wang & Wen (2025), JGR: Machine Learning and Computation 2(2), e2024JH000540, DOI [10.1029/2024JH000540](https://doi.org/10.1029/2024JH000540).
- **`references`:**
  - Hooper, Christophersen & Peters (1990), J. Hydrology, DOI [10.1016/0022-1694(90)90131-G](https://doi.org/10.1016/0022-1694(90)90131-G).
  - Christophersen et al. (1990), J. Hydrology, DOI [10.1016/0022-1694(90)90130-P](https://doi.org/10.1016/0022-1694(90)90130-P).
  - Hooper & Christophersen (1992), WRR, DOI [10.1029/92WR00706](https://doi.org/10.1029/92WR00706).
  - Hooper (2001), Hydrological Processes, DOI [10.1002/hyp.255](https://doi.org/10.1002/hyp.255).
  - Xu Fei & Harman (2022), HESS, DOI [10.5194/hess-26-1977-2022](https://doi.org/10.5194/hess-26-1977-2022).
  - Dymond (1981), GSA Memoir 154, DOI [10.1130/MEM154-p133](https://doi.org/10.1130/MEM154-p133).
  - Leinen & Pisias (1984), GCA, DOI [10.1016/0016-7037(84)90348-X](https://doi.org/10.1016/0016-7037(84)90348-X).
  - Zhu (2017), arXiv:[1708.05125](https://arxiv.org/abs/1708.05125).
  - Zhu et al. (2014), ISPRS J., DOI [10.1016/j.isprsjprs.2013.11.014](https://doi.org/10.1016/j.isprsjprs.2013.11.014).
  - Shaughnessy et al. (2021), HESS, DOI [10.5194/hess-25-3397-2021](https://doi.org/10.5194/hess-25-3397-2021). This is the source of the NMF baseline.
  - Zouaoui et al. (2023), IEEE TIP, DOI [10.1109/TIP.2023.3301769](https://doi.org/10.1109/TIP.2023.3301769). This is the source of the EDAA baseline.
  - MLCommons Science Benchmarks Ontology, arXiv:[2511.05614](https://arxiv.org/abs/2511.05614).

### Related software
Both packages are related by `analyzes`:
- **archetypes 0.8.0:** the SPGD-AA reference solution, DOI [10.5281/zenodo.15198941](https://doi.org/10.5281/zenodo.15198941). Source: <https://github.com/aleixalcacer/archetypes>.
- **emma-bench 0.1.0:** the loaders, scoring, leaderboard and Codabench bundle in this package. It is unregistered.

### Related ai model
None. The benchmark has no trained model. Its methods (SPGD-AA, k-means, NMF, CHEMMA, EDAA) are fitted to each dataset without supervision.

## Understanding the Data

### List of variable name(s), description(s), unit(s), and value labels for each variable in the dataset/file.
| Variable Name | Description | Unit | Value Labels / Range |
|---|---|---|---|
| sample_id | Row ID assigned by the loaders: `s0000…` (synthetic), `p000…` (Panola), `n<Sample No>` (Nazca), `L<line>S<sample>` (Jasper Ridge) | N/A | — |
| A–H | Synthetic features; each sample is a convex mixture of EM1–EM4 | arbitrary units | 0.116–1.287 (noise-free, α); 0.0–1.469 (noisy); 10.158–11.167 (shifted) |
| EM1–EM4 | Synthetic mixing proportions (ground truth only); rows sum to 1 | fraction | 0–1 |
| Alk | Panola alkalinity | µeq/L | −6.0 to 363.1 |
| SO4 | Panola sulfate | µeq/L | 1.70–224.0 |
| Na | Panola sodium | µeq/L | 25.2–261.3 |
| Mg | Panola magnesium | µeq/L | 27.2–107.0 |
| Ca | Panola calcium | µeq/L | 35.9–199.0 |
| Si | Panola dissolved silica | µmol/L | 42.7–472.5 |
| Al, Si, Mn, Fe, Cu, Ni, Zn, Ba | Nazca sediment elements on a carbonate-free basis (source columns `<El> (ppm)`); benchmark input is each row ÷ its 8-element sum | ppm → weight fraction | fraction 0.00012–0.830 |
| b001–b198 | Jasper Ridge AVIRIS reflectance, 198 bands, 399.4–2457.2 nm | reflectance | −0.0448 to 0.5437 |
| endmember | Reference row label | N/A | EM1–EM4; Organic, Hillslope, Groundwater; Detrital, Hydrothermal, Biogenic, Authigenic, Dissolution Residue; Tree, Water, Soil, Road |

### Related Schemas or Ontologies
- **Schema URL:** `not_applicable`. No formal schema file exists. `data/SCHEMA.md` is the human-readable data dictionary.
- **Semantic context:**
  - Linear (convex) mixing model: X = A·E + noise, with each row of A on the probability simplex.
  - Units are as tabulated above.
  - The corpus entry follows the MLCommons Science Benchmarks Ontology (arXiv:2511.05614).

### Codes used for missing data
| Code | Description |
|------|-------------|
| NaN | Appears only in `data/saved_results` (NMF outputs). It marks proportion rows outside the 0.9–1.1 sum filter and every end-member on the shifted sets (no solution). These values are never imputed and are counted in coverage. |

The benchmark inputs (X) have no missing values.

### Example of the contents
`synthetic/endmembers.csv` columns: `endmember, A, B, C, D, E, F, G, H`.

`panola/panola_data.csv`, first rows:

```
Alk,SO4,Na,Mg,Ca,Si
329,13.6997808,153.00612,84.73608,118.2156,325.9776
329,12.8997936,152.206088,83.15592,120.7096,328.9728
```

### Data Processing
**Copying.** The raw files were copied unchanged from upstream commit 76fcca1, with their Git LFS content resolved. The SHA-256 of each of the 26 files is recorded in `data/raw/MANIFEST.json`.

**Loading.** The benchmark loaders (`src/emma_bench/datasets.py`, `truth.py`) do the following:
- Read Nazca columns A:I of the SI workbook, strip ` (ppm)` from the column names and divide each row by its 8-element sum.
- Scale the Jasper Ridge ENVI BIL int16 values by 1/10,000 to get reflectance, and read pixels row-major.
- Assign sample IDs.

**Label correction.** The Jasper Ridge `end4.mat` rows are labelled Tree, Water, Soil, Road. This corrects the upstream notebook's soil/water swap.

**Saved results.** The NMF, CHEMMA and EDAA outputs are copied from upstream unchanged and never imputed.

### Software used to preprocess/ clean/ label the data
- **Upstream generator:** `scripts/data/generate_synthetic_data.py` at [endmembers@76fcca1](https://github.com/WEN-Research-Group/endmembers/blob/76fcca1e79e4df38ce9841950292285b17415455/scripts/data/generate_synthetic_data.py).
- **Benchmark scripts:** emma-bench 0.1.0 (`scripts/fetch_data.py`, `src/emma_bench/`).
- **Environment:**
  - Python 3.12 with numpy 1.26.4, pandas 3.0.6, scipy 1.11.4, scikit-learn 1.9.1, archetypes 0.8.0, spectral 0.25 and openpyxl 3.1.5 (`requirements.txt`).
  - The reference run used one ALCF Polaris node; the cross-check ran on macOS arm64.

## Semantic / Schema Information
- **Schema URL:** `not_applicable` (none published). `data/SCHEMA.md` is the data dictionary.
- **Semantic context:**
  - A linear convex mixing model.
  - Units: synthetic arbitrary units; Panola µeq/L (Si µmol/L); Nazca weight fraction; Jasper Ridge reflectance.
  - Benchmark metadata follows the MLCommons Science Benchmarks Ontology.
- **Domain metadata:**
  - p = 4 (synthetic), 3 (Panola), 5 (Nazca) and 4 (Jasper Ridge).
  - The Panola catchment is 41 ha.
  - 26 of the 224 Jasper Ridge bands were removed.

---

# ---- Reusable ----

## Citation
```bibtex
@article{wang2025spgdaa,
  author    = {Wang, Zanchenling and Wen, Tao},
  title     = {Inferring End-Members From Geoscience Data Using Simplex Projected Gradient Descent-Archetypal Analysis},
  journal   = {Journal of Geophysical Research: Machine Learning and Computation},
  volume    = {2},
  number    = {2},
  pages     = {e2024JH000540},
  year      = {2025},
  publisher = {American Geophysical Union (AGU)},
  doi       = {10.1029/2024JH000540}
}
```
Also cite the benchmark: Wang, Z. & Wen, T. (2026), *EMMA Benchmark: unsupervised end-member extraction from geoscience mixtures*, v0.1.0, <https://www.codabench.org/competitions/18387/>. Cite the original Panola, Nazca and Jasper Ridge sources as well.

## License and Usage Rights
Licensed under `MIT` (MIT License). See <https://opensource.org/licenses/MIT>.
- The authors permit redistribution of the data (confirmed 2026-10-15), and upstream releases it with its MIT-licensed repository.
- Third-party originals should be cited to their sources:
  - Panola, via CHEMMA, which has no license file;
  - Nazca, from the Pisias et al. (2013) supporting information;
  - Jasper Ridge, via Hugging Face, which lists its license as unknown.

## Maintenance & Updates
- **Maintainer:** Tao Wen (Syracuse University, twen08@syr.edu). Level: `Project_Managed`.
- **Updates:** ad hoc.
- **Versioning:** the benchmark package uses semantic versioning (0.1.0 released 2026-10-15). Raw inputs are pinned to upstream commit 76fcca1 and fixed by SHA-256, so any data change requires a new version.
- **Retention:** the package itself has no stated policy. The paper's Zenodo archive (10.5281/zenodo.15178390), which holds byte-identical copies of all raw files and saved results, is kept for the lifetime of the Zenodo repository under [Zenodo's policy](https://about.zenodo.org/policies/).

## Data Characteristics
**Variables.** See the variable table above.

**Splits.** There are no train/test splits; the phases group the datasets instead:
- **dev:** synthetic_noisefree and synthetic_noisy. They are not ranked and can be used freely.
- **test:** synthetic_alpha2, synthetic_alpha4, synthetic_alpha2_shifted, synthetic_alpha4_shifted, panola, nazca and jasper_ridge. They must not be used for tuning.

No sample appears in both phases.

**Spatial coverage.**
- Panola Mountain Research Watershed, Georgia, USA (41 ha).
- Nazca Plate surface sediments, southeastern Pacific. Samples span 39.05°S–0.29°N and 134.55°W–79.16°W, from the source file's coordinates; this is the card's bounding box. Sample 452 is listed at 0, 0.
- Jasper Ridge Biological Preserve, California, USA.

**Temporal coverage.**
- Panola samples were collected 1985-10-01 to 1988-09-30.
- The paper and SI give no dates for the Nazca sediment sampling or the Jasper Ridge AVIRIS flight.

**Modalities.** Tabular, plus one hyperspectral image.

## Data Quality & Limitations
**Completeness**
- All nine inputs are complete, with no missing or invalid values in any X.
- The saved upstream baselines are partial:
  - NMF proportions are NaN outside the 0.9–1.1 row-sum filter (644/1000 noise-free, 794 noisy, 918 α=2, 938 α=4).
  - NMF found no solution on the shifted sets.
  - CHEMMA and EDAA published end-members only.

**Known issues**
- The real-data reference end-members are literature estimates, not measured truth:
  - Panola uses field medians from Hooper (1990).
  - Nazca uses Dymond (1981), whose dissolution-residue end-member no sample approaches, so a 4-end-member mean is also reported.
  - Jasper Ridge uses `end4.mat`.
- The upstream Jasper Ridge soil and water labels were swapped; this is corrected here.
- The `end4.mat` abundances match the image only in column-major pixel order. Abundances are not scored.
- The Mg value of the Panola organic end-member differs between Hooper (1990) and Xu Fei & Harman (2022); Hooper is used.
- In the Nazca source file, sample 452 has coordinates 0, 0, which are probably missing. Coordinates are not benchmark inputs.

**Validation** (recorded in `docs/VALIDATION.md`, 2026-10-15)
- The SHA-256 of all 26 raw files matches the manifest.
- The synthetic files regenerate exactly from the upstream generator (within 4.4e-16, and 5.3e-15 for the shifted sets).
- The numpy Jasper Ridge reader matches `spectral` exactly.
- The dev and test phases share 0 rows.
- An SPGD-AA rerun reproduces the published outputs.

**Cross-checks against the paper's Supporting Information** (2026-10-16):
- The reference end-members match:
  - Table S1 exactly (synthetic, and S1 + 10 for the shifted sets);
  - Table S4 exactly (Panola field medians, and CHEMMA means mapped Red→Organic, Green→Hillslope, Blue→Groundwater);
  - Table S5 exactly for QFA, and within 5e-6 rounding for Dymond (1981).
- Five spot-checked Table S2 values match to 3 decimals.
- All 26 raw files and all 20 saved-result CSVs are byte-identical to the Zenodo archive the paper cites.

**Noise**
- synthetic_noisy has Gaussian noise (σ = 0.1) on the end-members and the samples, clipped at 0 (15 values affected).
- The real datasets carry measurement noise as published.
- Jasper Ridge keeps 0.81% small negative reflectances.

**Uncertainty**
- Scores on the real datasets inherit the uncertainty of the literature reference end-members.
- Dymond's (1981) model fits poorly for the minor elements Mn, Ni, Cu and Zn (paper Sec. 2.4.3).
- The truth-free relative residual sum of squares is reported alongside them.

**Limitations**
- The synthetic test sets share the dev end-members. They test robustness to fewer near-pure samples and to a shift, not recovery of unseen end-members.
- The ground truth is public, so the test phase measures generalization across datasets, not hidden labels.

## Integrity & Versioning
**Checksums.** SHA-256 checksums are available. `data/raw/MANIFEST.json` lists the SHA-256, size and upstream URL of each of the 26 raw files.
- The card's `checksum_value` is the SHA-256 of the manifest itself: `4c9d2fe0f26bdb0f4f718816c8b0d254b7307b8d9fe33419f498c950b2653d23`.
- Verify with `python scripts/fetch_data.py --verify`.
- The Zenodo archive file `endmembers-v0.0.0-alpha.zip` has md5 `c8949ecdd41d0e211f80a1f73110d2c9`, and its raw files match the manifest's SHA-256 values.

**Versioning.** The package uses semantic versioning, and the inputs are pinned to an upstream commit.

---

# ---- Governed Use ----

## Access and Permissions
- **Export control:** `No`. Foreign national access is allowed.
- **Privacy:** `No`. PII is `No` and PHI is `No`; no privacy regime applies.
- **Compliance:**
  - DOE data management plan: not applicable (the work was NSF-funded).
  - OSTI E-Link 2.0 compliance: `Unknown`. Nothing has been submitted to OSTI, and neither the paper nor the SI addresses it.
  - IRB: not applicable (no human subjects).

## Access conditions
- IP restriction: `None`.
- Agreement required: `No`.
- Public release status: `Approved`.
- Record status: `Unknown`.

**Use governance**
- **Current use:** the live Codabench competition 18387 and Genesis Mission hackathon demonstrations.
- **Intended use:** evaluating and comparing unsupervised end-member extraction methods.
- **Permitted use:** any use under the MIT license, with citation.
- **Out of scope:**
  - tuning per test dataset against its public ground truth;
  - outside-data augmentation for leaderboard results;
  - treating literature end-members as measured truth;
  - basing regulatory or water-quality decisions on inferred end-members alone.
- **Prohibited:** nothing beyond the MIT terms.

## Review Provenance

### Release review process
**Internal QA: `docs/VALIDATION.md`**, dated 2026-10-15. Authority: the benchmark authors (self-review).
- **Purpose:** check data provenance, reproduction and metrics.
- **Scope:** internal checks only.
- **Other reviews:** no institutional, export-control or IRB review was performed. None is needed for these public data, which involve no human subjects.

---

# ---- AI Usable ----

## AI / Machine Learning Considerations
**Training: `Conditional`.** Training is permitted under the MIT license. For benchmark results, only the dev-phase datasets may be used for development. The test-phase datasets and every ground-truth file must not be used for training or tuning, and outside-data augmentation is not allowed.

**Inference and evaluation: `Yes`.** Evaluation is the dataset's main purpose.

**Restrictions.** A method's only valid input is a dataset's X plus p. It must not read:
- the ground-truth end-member files;
- the `mixing_proportions` files;
- `end4.mat`;
- the `*_ratio.csv` or `LP1984_*` files;
- `xufei2022_endmembers.csv`;
- `data/saved_results/`.

`SUBMISSION.md` asks for a declaration.

**Bias risks**
- Coverage is small and domain-specific: three real datasets (one watershed, one ocean plate, one hyperspectral scene) and synthetic data with 4 end-members × 8 features.
- The synthetic test sets reuse the dev end-members.
- Literature reference end-members can favour methods that agree with prior interpretations.

**Safety.** There are no known safety risks; the data are public, non-sensitive environmental measurements and synthetic mixtures.

**Human review: `Yes`.** It is recommended before drawing domain conclusions from inferred end-members.

---

# Additional Information
**Card generation.** This card was generated with the [datacard-generator skill](https://github.com/jeanbez/datacard-generator-skill) v2.1.0 in **provisional** mode (template 2.1.0).
- It is Genesis Datacard v2.0.0 ([doi:10.18141/3376151](https://doi.org/10.18141/3376151)) plus the provisional xCards registry spine. This is not an upstream v2.1 release.
- To register it with the xCard registry, submit the `.xcard.md` export produced by `export_xcard.py`.

**Identifiers.** The benchmark has no DOI of its own yet. `primary_id` is `unregistered`, and the Codabench URL is an additional identifier. Minting a Zenodo DOI for v0.1.0 would close this gap.
