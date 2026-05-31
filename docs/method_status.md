# Method status

Status labels:

- TODO: planned but not implemented/tested yet.
- PASS_ENV: required package/environment loads successfully, but wrapper and benchmark smoke test are not finished yet.
- PASS_WRAPPER: method trains and predicts on package example or synthetic/minimal data.
- PASS_SMOKE: method runs in the common benchmark pipeline on smoke-test folds.
- PASS_FULL: method completed the full `cv_10x10` benchmark protocol.
- PARTIAL: implemented but with important limitations.
- FAIL: attempted but not currently runnable.
- SKIPPED: intentionally excluded, with reason.

| method_id | status | notes |
|---|---:|---|
| majority | PASS_FULL | Majority-class baseline completed full `cv_10x10` protocol on all eight datasets. |
| switchbox_tsp | PASS_FULL | Classical TSP wrapper completed full `cv_10x10` protocol on all eight datasets; internal implementation used because switchBox k=1 has an object-shape edge case. |
| switchbox_ktsp | PASS_FULL | switchBox k-TSP completed full `cv_10x10` protocol on all eight datasets. |
| tspdt_bigtsp | PASS_FULL | BigTSP TSP-tree completed full `cv_10x10` protocol on all eight datasets. Prediction requires `newdata` with response in the first column. |
| rrf_ranktreeensemble | PASS_FULL | ranktreeEnsemble Random Rank Forest completed full `cv_10x10` protocol on all eight datasets. |
| rtb_ranktreeensemble | PASS_ENV | `ranktreeEnsemble::rboost` package environment available; full benchmark not run unless required for manuscript coverage. |
| glmnet_enet | PASS_ENV | `glmnet` installed and loadable; non-relational benchmark wrapper pending. |
| svm_linear | PASS_ENV | `e1071` installed and loadable; non-relational benchmark wrapper pending. |
| ranger_rf | PASS_ENV | `ranger` installed and loadable; non-relational benchmark wrapper pending. |
| xgboost_shallow | PASS_ENV | `xgboost` installed and loadable; source build was slow but successful. |
| svm_ktsp | TODO | Requires definition of exact historical implementation. |
| ger | TODO | Requires verification of implementation used in manuscript. |
| rankcompv2 | TODO | Requires verification of implementation used in manuscript. |
| knn_rrm | TODO | Python/RRM relational kNN candidate; probe later in isolated Python environment. |
