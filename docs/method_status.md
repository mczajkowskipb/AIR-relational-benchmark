# Method status

This file tracks implementation and validation status of methods in the AIR relational benchmark repository.

Status labels:

- TODO: planned but not implemented/tested yet.
- PASS_ENV: required package/environment loads successfully, but wrapper and benchmark smoke test are not finished yet.
- PASS_WRAPPER: wrapper runs on synthetic/minimal data.
- PASS_SMOKE: method runs in the common benchmark pipeline on smoke-test folds.
- PASS_FULL: method completed the full benchmark protocol.
- PARTIAL: implemented but with important limitations.
- FAIL: attempted but not currently runnable.
- SKIPPED: intentionally excluded, with reason.

| method_id | status | notes |
|---|---:|---|
| majority | PASS_ENV | Internal baseline; no external package required. |
| glmnet_enet | PASS_ENV | `glmnet` installed and loadable. |
| svm_linear | PASS_ENV | `e1071` installed and loadable. |
| ranger_rf | PASS_ENV | `ranger` installed and loadable. |
| xgboost_shallow | PASS_ENV | `xgboost` installed and loadable; source build was slow but successful. |
| switchbox_tsp | PASS_ENV | `switchBox` installed and loadable; TSP/KTSP functions available. |
| switchbox_ktsp | PASS_ENV | `switchBox` installed and loadable; TSP/KTSP functions available. |
| svm_ktsp | TODO | Requires definition of exact historical implementation. |
| ger | TODO | Requires verification of implementation used in manuscript. |
| rankcompv2 | TODO | Requires verification of implementation used in manuscript. |
| ranktreeensemble | TODO | Requires verification of implementation used in manuscript. |
| tspdt_bigtsp | PASS_ENV | `BigTSP` installed from CRAN archive; `tsp.tree` exported. |
