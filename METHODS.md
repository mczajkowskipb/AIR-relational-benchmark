# Methods

The benchmark includes relational/rank-based methods and conventional reference ML baselines.

## Compact relational rules

| Method ID | Display name | Description |
|---|---|---|
| `switchbox_tsp` | TSP | Single top-scoring pair rule from `switchBox` |
| `switchbox_ktsp` | k-TSP | Multi-pair voting rule from `switchBox` |
| `tspdt_bigtsp` | TSPDT | TSP-based decision tree from `BigTSP` |

## Python gene-pair wrappers

These are benchmark-compatible wrappers inspired by an external gene-pair notebook. They are not verbatim notebook executions.

| Method ID | Display name | Description |
|---|---|---|
| `py_tsp` | Python TSP-like | Single-pair TSP-like rule |
| `py_tsp_svm` | TSP+SVM | TSP-like pair encoding followed by SVM |
| `py_tsp_rf` | TSP+RF | TSP-like pair encoding followed by Random Forest |
| `py_reos` | REO-like | REO-style relational rule/score |
| `py_reos_svm` | REO+SVM | REO-like pair encoding followed by SVM |

## Relational metric / rank ensemble

| Method ID | Display name | Description |
|---|---|---|
| `pyrrm_knn5` | RRM-kNN | kNN using the pyrrm relative-relation metric, k=5 |
| `rrf_ranktreeensemble` | RRF | Random Rank Forest from `ranktreeEnsemble` |

## Conventional reference baselines

| Method ID | Display name |
|---|---|
| `glmnet_enet` | elastic-net logistic regression |
| `svm_linear` | linear SVM |
| `knn_euclidean` | Euclidean kNN |
| `rpart_tree` | CART decision tree |
| `ranger_rf` | Random Forest |
| `xgboost_shallow` | shallow XGBoost |
| `majority` | majority-class baseline |

## Interpretation note

The method groups are descriptive. They should not be read as a calibrated interpretability score.

Some methods use explicit within-sample relations and remain auditable, but differ in their final model endpoint. For example, TSP is a compact global rule, while RRM-kNN uses a relational distance in an instance-based classifier.
