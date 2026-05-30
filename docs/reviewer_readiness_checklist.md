# Reviewer readiness checklist

This file tracks how the repository addresses reproducibility and benchmarking concerns raised during review.

| reviewer concern | repository response | status |
|---|---|---:|
| Public code availability | GitHub repository with scripts, configs, method registry, and reproducibility docs. | IN_PROGRESS |
| Reproducible method list | `config/methods.csv`, `docs/method_status.md`, and `docs/manuscript_method_coverage.md`. | IN_PROGRESS |
| Methods from manuscript benchmark | TSP/k-TSP, TSP-tree, and Random Rank Forest have passed wrapper-level functional probes. Remaining methods are explicitly tracked. | IN_PROGRESS |
| Leakage-controlled preprocessing | `R/core/preprocessing.R` implements train-only MAD filtering, median imputation, and scaling. | PASS_WRAPPER |
| Additional metrics beyond accuracy | `R/core/metrics.R` computes accuracy, balanced accuracy, macro-F1, MCC, sensitivity/specificity, AUC, Brier, logloss where applicable, and confusion counts. | PASS_WRAPPER |
| Classical ML baselines | Packages are installed and loadable; wrappers still to be implemented. | PASS_ENV |
| Runtime tracking | Common interface includes runtime table; per-method benchmark integration still pending. | IN_PROGRESS |
| Model size / interpretability tracking | Common interface supports model_info; relation/tree/rule extraction available for some methods. | IN_PROGRESS |
| Failed or unavailable methods | To be documented explicitly with PASS / PARTIAL / FAIL / SKIPPED reason. | IN_PROGRESS |
| Full benchmark reproducibility | Fold generation, data preparation, job grid, and collection scripts still pending. | TODO |
