# pyrrm relational kNN cv10x10 benchmark summary

This document summarizes the full pyrrm relational kNN benchmark.

Method:

- `pyrrm_knn5`
- metric: `pyrrm.relative_relation_metric`
- classifier: `sklearn.neighbors.KNeighborsClassifier`
- k = 5
- train-only MAD feature filtering
- n_features = 50

Protocol:

- 8 datasets
- 10 repeats
- 10 folds per repeat
- 800 total jobs
- 800 completed jobs expected
- 0 failed jobs expected

## Overall summary

| method_id | mean balanced accuracy | mean macro-F1 | mean MCC | mean n_features | k |
|---|---:|---:|---:|---:|---:|
| pyrrm_knn5 | 0.6723 | 0.6519 | 0.3401 | 50.0 | 5.0 |

## Dataset-level summary

| dataset_id | balanced accuracy | macro-F1 | MCC |
|---|---:|---:|---:|
| GDS2771 | 0.6437 | 0.6381 | 0.3004 |
| GSE10072 | 0.9688 | 0.9687 | 0.9420 |
| GSE17920 | 0.5215 | 0.5009 | 0.0532 |
| GSE19804 | 0.9558 | 0.9555 | 0.9173 |
| GSE25837 | 0.4664 | 0.4289 | -0.0848 |
| GSE27272 | 0.4502 | 0.4040 | -0.1425 |
| GSE3365 | 0.7990 | 0.7652 | 0.5822 |
| GSE6613 | 0.5732 | 0.5541 | 0.1528 |

## Interpretation note

`pyrrm_knn5` is included as the exact pyrrm relative-relation metric used inside a standard sklearn kNN classifier. It is therefore distinct from the ordinary Euclidean kNN baseline already included in the R benchmark.