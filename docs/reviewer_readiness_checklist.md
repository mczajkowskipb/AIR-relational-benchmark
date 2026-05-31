# Reviewer readiness checklist

This file tracks how the repository addresses reproducibility and benchmarking concerns raised during review.

| reviewer concern | repository response | status |
|---|---|---:|
| Public code availability | GitHub repository with scripts, configs, method registry, and reproducibility docs. | PASS |
| Reproducible method list | `config/methods.csv`, `docs/method_status.md`, and `docs/manuscript_method_coverage.md`. | PASS |
| Methods from manuscript benchmark | TSP, k-TSP, TSP-tree, and Random Rank Forest are implemented and completed the full `cv_10x10` protocol. | PASS |
| Leakage-controlled preprocessing | `R/core/preprocessing.R` implements train-only MAD filtering, median imputation, and optional scaling. | PASS |
| Original datasets | GEO/GDS download and preparation workflow implemented; dataset manifests committed. | PASS |
| Explicit label mapping | Binary class definitions recorded in `config/label_mapping.csv` and `docs/label_mapping_decisions.md`. | PASS |
| Fixed CV folds | Stratified `smoke_2x2` and `cv_10x10` folds generated and committed with balance checks. | PASS |
| Full benchmark reproducibility | `cv_10x10` job grid completed: 4000 jobs, 4000 done, 0 failed. | PASS |
| Additional metrics beyond accuracy | Accuracy, balanced accuracy, macro-F1, MCC, sensitivity/specificity and confusion counts are computed; probability metrics only where valid. | PASS |
| Runtime tracking | Runtime summaries collected for all full benchmark jobs. | PASS |
| Model size / interpretability tracking | Model-info summaries collected; relation/tree/rule-capable methods tracked. | PASS |
| Classical ML baselines | Required packages are installed and loadable; wrappers pending if needed for reviewer-requested non-relational baselines. | PARTIAL |
| Failed or unavailable methods | Remaining candidate methods are explicitly tracked as TODO/PARTIAL rather than silently omitted. | IN_PROGRESS |
