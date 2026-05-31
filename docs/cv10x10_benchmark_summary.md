# Full cv10x10 benchmark summary

This document summarizes the full benchmark run over the eight legacy datasets.

Protocol:

- 8 datasets
- 10 repeats
- 10 folds per repeat
- 11 methods
- 8800 total jobs
- 8800 completed jobs
- 0 failed jobs

The full results are stored in:

- `results/summary/cv_10x10_dataset_method_summary.csv`
- `results/summary/cv_10x10_overall_method_summary.csv`
- `results/summary/cv_10x10_runtime_summary.csv`
- `results/summary/cv_10x10_model_info_summary.csv`
- `results/summary/cv_10x10_job_status_summary.csv`

## Overall method-level summary

The table below reports the mean over dataset-level means, so each dataset contributes equally.

| method_id | mean accuracy | mean balanced accuracy | mean macro-F1 | mean MCC |
|---|---:|---:|---:|---:|
| ranger_rf | 0.7879 | 0.7150 | 0.7014 | 0.4548 |
| svm_linear | 0.7494 | 0.7149 | 0.7062 | 0.4318 |
| glmnet_enet | 0.7867 | 0.7073 | 0.6711 | 0.4238 |
| xgboost_shallow | 0.7753 | 0.6993 | 0.6802 | 0.4195 |
| knn_euclidean | 0.7505 | 0.6900 | 0.6746 | 0.3836 |
| switchbox_tsp | 0.6654 | 0.6838 | 0.6456 | 0.3678 |
| rpart_tree | 0.7151 | 0.6739 | 0.6673 | 0.3589 |
| tspdt_bigtsp | 0.7100 | 0.6706 | 0.6649 | 0.3497 |
| switchbox_ktsp | 0.6668 | 0.6612 | 0.6431 | 0.3342 |
| rrf_ranktreeensemble | 0.6505 | 0.6107 | 0.5729 | 0.2221 |
| majority | 0.6160 | 0.5000 | 0.3790 | 0.0000 |

## Runtime summary

Mean total job time includes dataset loading and preprocessing overhead, not only model fitting.

| method_id | jobs | mean total seconds/job | max total seconds/job |
|---|---:|---:|---:|
| majority | 800 | 9.16 | 17.93 |
| switchbox_ktsp | 800 | 9.21 | 17.84 |
| knn_euclidean | 800 | 9.48 | 17.72 |
| rpart_tree | 800 | 9.54 | 18.09 |
| ranger_rf | 800 | 9.55 | 18.11 |
| svm_linear | 800 | 9.57 | 17.97 |
| xgboost_shallow | 800 | 9.57 | 17.99 |
| switchbox_tsp | 800 | 10.26 | 18.95 |
| glmnet_enet | 800 | 10.27 | 18.55 |
| rrf_ranktreeensemble | 800 | 11.12 | 20.18 |
| tspdt_bigtsp | 800 | 29.25 | 44.62 |

## Interpretation caution

These results reconstruct the legacy eight-dataset benchmark under an explicit, leakage-controlled protocol. The datasets are binary but heterogeneous: some are disease-vs-control tasks, while others are phenotype or clinical endpoint contrasts. Class definitions are documented in `config/label_mapping.csv` and `docs/label_mapping_decisions.md`.

The classical ML baselines are intentionally lightweight and non-nested: they are included as reviewer-facing reference baselines, not as exhaustively tuned state-of-the-art models.

Hard-label methods do not report calibrated probabilities, so AUC/Brier/logloss are unavailable where no probability-like score is provided.
