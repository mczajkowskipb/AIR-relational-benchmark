# Combined cv10x10 benchmark summary

This document combines all currently completed benchmark families:

- R relational methods
- R lightweight classical reference baselines
- Python gene-pair wrappers inspired by the wucc009 notebook
- pyrrm relational kNN

Completed jobs represented in the repository summaries:

- R benchmark: 8800 jobs
- Python gene-pair benchmark: 4000 jobs
- pyrrm benchmark: 800 jobs
- Total summarized jobs: 13600 jobs

## Overall ranking by mean balanced accuracy

| rank | method_id | group | mean balanced accuracy | mean macro-F1 | mean MCC |
|---:|---|---|---:|---:|---:|
| 1 | ranger_rf | r_classical_reference | 0.7150 | 0.7014 | 0.4548 |
| 2 | svm_linear | r_classical_reference | 0.7149 | 0.7062 | 0.4318 |
| 3 | glmnet_enet | r_classical_reference | 0.7073 | 0.6711 | 0.4238 |
| 4 | xgboost_shallow | r_classical_reference | 0.6993 | 0.6802 | 0.4195 |
| 5 | knn_euclidean | r_classical_reference | 0.6900 | 0.6746 | 0.3836 |
| 6 | py_tsp_rf | python_gene_pair | 0.6876 | 0.6658 | 0.3861 |
| 7 | switchbox_tsp | r_relational | 0.6838 | 0.6456 | 0.3678 |
| 8 | py_reos_svm | python_gene_pair | 0.6777 | 0.6711 | 0.3621 |
| 9 | py_tsp_svm | python_gene_pair | 0.6759 | 0.6692 | 0.3585 |
| 10 | rpart_tree | r_classical_reference | 0.6739 | 0.6673 | 0.3589 |
| 11 | pyrrm_knn5 | pyrrm_relational_knn | 0.6723 | 0.6519 | 0.3401 |
| 12 | tspdt_bigtsp | r_relational | 0.6706 | 0.6649 | 0.3497 |
| 13 | py_tsp | python_gene_pair | 0.6613 | 0.6398 | 0.3256 |
| 14 | switchbox_ktsp | r_relational | 0.6612 | 0.6431 | 0.3342 |
| 15 | py_reos | python_gene_pair | 0.6583 | 0.6315 | 0.3252 |
| 16 | rrf_ranktreeensemble | r_relational | 0.6107 | 0.5729 | 0.2221 |
| 17 | majority | r_classical_reference | 0.5000 | 0.3790 | 0.0000 |

## Best method per dataset

| dataset_id | method_id | group | balanced accuracy | macro-F1 | MCC |
|---|---|---|---:|---:|---:|
| GDS2771 | ranger_rf | r_classical_reference | 0.7367 | 0.7335 | 0.5025 |
| GSE10072 | ranger_rf | r_classical_reference | 0.9809 | 0.9817 | 0.9672 |
| GSE17920 | ranger_rf | r_classical_reference | 0.6731 | 0.6808 | 0.4575 |
| GSE19804 | pyrrm_knn5 | pyrrm_relational_knn | 0.9558 | 0.9555 | 0.9173 |
| GSE25837 | switchbox_tsp | r_relational | 0.5664 | 0.4541 | 0.1255 |
| GSE27272 | svm_linear | r_classical_reference | 0.5454 | 0.5375 | 0.0927 |
| GSE3365 | glmnet_enet | r_classical_reference | 0.9422 | 0.9374 | 0.8848 |
| GSE6613 | switchbox_ktsp | r_relational | 0.6143 | 0.5825 | 0.2613 |

## Best relational / gene-pair / pyrrm method per dataset

| dataset_id | method_id | group | balanced accuracy | macro-F1 | MCC |
|---|---|---|---:|---:|---:|
| GDS2771 | py_reos_svm | python_gene_pair | 0.6890 | 0.6860 | 0.3878 |
| GSE10072 | switchbox_ktsp | r_relational | 0.9701 | 0.9704 | 0.9452 |
| GSE17920 | rrf_ranktreeensemble | r_relational | 0.6128 | 0.5922 | 0.2227 |
| GSE19804 | pyrrm_knn5 | pyrrm_relational_knn | 0.9558 | 0.9555 | 0.9173 |
| GSE25837 | switchbox_tsp | r_relational | 0.5664 | 0.4541 | 0.1255 |
| GSE27272 | switchbox_tsp | r_relational | 0.5040 | 0.4353 | 0.0182 |
| GSE3365 | py_tsp | python_gene_pair | 0.8654 | 0.8296 | 0.7061 |
| GSE6613 | switchbox_ktsp | r_relational | 0.6143 | 0.5825 | 0.2613 |

## Interpretation note

The combined table should not be read as a claim that all methods are directly equivalent implementations from the original publications. The R methods and classical baselines are benchmark wrappers in the AIR repository. The Python gene-pair methods are benchmark-compatible wrappers inspired by the external notebook. The pyrrm result uses the exact pyrrm relative-relation metric inside sklearn kNN.

Dataset-level tables are more informative than the global mean because the behavior is strongly dataset-dependent.