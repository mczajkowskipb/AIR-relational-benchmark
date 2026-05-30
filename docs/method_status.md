# Method status

Status labels:

- TODO: planned but not implemented/tested yet.
- PASS_ENV: required package/environment loads successfully, but wrapper and benchmark smoke test are not finished yet.
- PASS_WRAPPER: method trains and predicts on package example or synthetic/minimal data.
- PASS_SMOKE: method runs in the common benchmark pipeline on smoke-test folds.
- PASS_FULL: method completed the full benchmark protocol.
- PARTIAL: implemented but with important limitations.
- FAIL: attempted but not currently runnable.
- SKIPPED: intentionally excluded, with reason.

| method_id | status | notes |
|---|---:|---|
| majority | PASS_SMOKE | Majority-class baseline passed real-fold smoke test on all eight datasets. |
| glmnet_enet | PASS_ENV | `glmnet` installed and loadable. |
| svm_linear | PASS_ENV | `e1071` installed and loadable. |
| ranger_rf | PASS_ENV | `ranger` installed and loadable. |
| xgboost_shallow | PASS_ENV | `xgboost` installed and loadable; source build was slow but successful. |
| switchbox_tsp | PASS_WRAPPER | `switchBox` installed and loadable; k-TSP training/classification passed on package example data. |
| switchbox_ktsp | PASS_WRAPPER | `switchBox` installed and loadable; k-TSP training/classification passed on package example data. |
| svm_ktsp | TODO | Requires definition of exact historical implementation. |
| ger | TODO | Requires verification of implementation used in manuscript. |
| rankcompv2 | TODO | Requires verification of implementation used in manuscript. |
| ranktreeensemble | TODO | Requires verification of implementation used in manuscript. |
| tspdt_bigtsp | PASS_WRAPPER | `BigTSP` installed from CRAN archive; `tsp.tree` exported and functional probe passed. Prediction requires `newdata` with response in the first column. |
