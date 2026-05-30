# Method status

This file tracks which methods are implemented, tested, and included in each benchmark protocol.

Status labels:

- TODO: planned but not implemented/tested yet.
- PASS: implemented and passed smoke tests.
- PARTIAL: implemented but has limitations.
- FAIL: attempted but not currently runnable.
- SKIPPED: intentionally excluded, with reason.

| method_id | status | notes |
|---|---:|---|
| majority | TODO | Internal baseline. |
| glmnet_enet | TODO | Regularized logistic regression. |
| svm_linear | TODO | Linear SVM baseline. |
| ranger_rf | TODO | Random forest baseline. |
| xgboost_shallow | TODO | Shallow/default gradient boosting baseline. |
| switchbox_tsp | TODO | TSP through switchBox. |
| switchbox_ktsp | TODO | k-TSP through switchBox. |
| svm_ktsp | TODO | Requires verification of exact historical implementation. |
| ger | TODO | Requires verification of implementation used in manuscript. |
| rankcompv2 | TODO | Requires verification of implementation used in manuscript. |
| ranktreeensemble | TODO | Requires verification of implementation used in manuscript. |
| tspdt_bigtsp | TODO | Candidate implementation: BigTSP::tsp.tree. |
