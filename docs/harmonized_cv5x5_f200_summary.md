# Harmonized cv5x5 f200 benchmark summary

This benchmark uses a harmonized feature-universe setting:

- 8 datasets
- 5 repeats
- 5 folds per repeat
- train-only MAD filtering to 200 features for all methods
- balanced accuracy as the primary metric

Completed valid jobs:

- R methods excluding BigTSP/TSPDT: 2000 jobs
- Python gene-pair wrappers: 1000 jobs
- pyrrm relational kNN: 200 jobs
- valid completed jobs: 3200

Technical failure:

- `tspdt_bigtsp`: 200/200 failed at f200 due to `protect(): protection stack overflow`; excluded from the valid f200 comparison.

## Overall ranking by mean balanced accuracy

| rank | method_id | family | mean balanced accuracy | mean macro-F1 | mean MCC |
|---:|---|---|---:|---:|---:|
| 1 | svm_linear | R | 0.7244 | 0.7194 | 0.4495 |
| 2 | ranger_rf | R | 0.7208 | 0.7104 | 0.4653 |
| 3 | glmnet_enet | R | 0.7083 | 0.6721 | 0.4226 |
| 4 | xgboost_shallow | R | 0.7069 | 0.6935 | 0.4287 |
| 5 | py_tsp_rf | python_gene_pair | 0.6974 | 0.6850 | 0.3996 |
| 6 | pyrrm_knn5 | pyrrm | 0.6935 | 0.6802 | 0.3850 |
| 7 | py_tsp_svm | python_gene_pair | 0.6848 | 0.6818 | 0.3729 |
| 8 | py_reos_svm | python_gene_pair | 0.6848 | 0.6819 | 0.3729 |
| 9 | knn_euclidean | R | 0.6799 | 0.6681 | 0.3606 |
| 10 | rpart_tree | R | 0.6767 | 0.6736 | 0.3620 |
| 11 | py_reos | python_gene_pair | 0.6760 | 0.6532 | 0.3589 |
| 12 | switchbox_ktsp | R | 0.6741 | 0.6576 | 0.3543 |
| 13 | py_tsp | python_gene_pair | 0.6693 | 0.6453 | 0.3395 |
| 14 | switchbox_tsp | R | 0.6688 | 0.6445 | 0.3387 |
| 15 | rrf_ranktreeensemble | R | 0.6569 | 0.6239 | 0.3320 |
| 16 | majority | R | 0.5000 | 0.3790 | 0.0000 |

## Best method per dataset

| dataset_id | method_id | family | balanced accuracy | macro-F1 | MCC |
|---|---|---|---:|---:|---:|
| GDS2771 | glmnet_enet | R | 0.7277 | 0.7261 | 0.4666 |
| GSE10072 | glmnet_enet | R | 0.9863 | 0.9868 | 0.9751 |
| GSE17920 | ranger_rf | R | 0.6666 | 0.6823 | 0.4443 |
| GSE19804 | py_reos | python_gene_pair | 0.9583 | 0.9582 | 0.9193 |
| GSE19804 | py_tsp_rf | python_gene_pair | 0.9583 | 0.9582 | 0.9199 |
| GSE25837 | glmnet_enet | R | 0.5000 | 0.4295 | 0.0000 |
| GSE25837 | majority | R | 0.5000 | 0.4295 | 0.0000 |
| GSE27272 | svm_linear | R | 0.5749 | 0.5707 | 0.1475 |
| GSE3365 | svm_linear | R | 0.9427 | 0.9370 | 0.8796 |
| GSE6613 | py_reos_svm | python_gene_pair | 0.6215 | 0.6179 | 0.2492 |
| GSE6613 | py_tsp_svm | python_gene_pair | 0.6215 | 0.6179 | 0.2492 |

## Best relational / rank-based method per dataset

| dataset_id | method_id | family | balanced accuracy | macro-F1 | MCC |
|---|---|---|---:|---:|---:|
| GDS2771 | py_tsp_rf | python_gene_pair | 0.6850 | 0.6816 | 0.3886 |
| GSE10072 | pyrrm_knn5 | pyrrm | 0.9803 | 0.9809 | 0.9636 |
| GSE17920 | switchbox_tsp | R | 0.5801 | 0.5488 | 0.1511 |
| GSE19804 | py_reos | python_gene_pair | 0.9583 | 0.9582 | 0.9193 |
| GSE25837 | rrf_ranktreeensemble | R | 0.4879 | 0.4283 | -0.0290 |
| GSE27272 | py_reos | python_gene_pair | 0.5399 | 0.4632 | 0.0901 |
| GSE3365 | py_tsp_rf | python_gene_pair | 0.8664 | 0.8644 | 0.7392 |
| GSE6613 | py_reos_svm | python_gene_pair | 0.6215 | 0.6179 | 0.2492 |

## Interpretation note

This harmonized benchmark is intended as the cleaner comparison for updated Figure 4-style visualization because all included valid methods use the same 200-feature train-only MAD universe. The previous cv10x10 benchmark remains useful as a broader repository validation run.