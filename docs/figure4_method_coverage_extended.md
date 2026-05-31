# Extended Figure 4 / benchmark method coverage

This document tracks methods from the manuscript benchmark, Figure 4, and adjacent relational/rank-based method families.

The goal is not to claim that all methods are already fully benchmarked. The goal is to avoid silent omissions and to separate completed, probed, planned, and status-only methods.

## Status legend

| status | meaning |
|---|---|
| PASS_FULL | Completed full `cv_10x10` benchmark. |
| PASS_ENV | Package/environment available, but full benchmark not run. |
| PROBE_ONLY | Source inspected; wrapper not yet converted into benchmark interface. |
| TODO | Known target; source/definition still needs confirmation. |
| STATUS_ONLY | Important method, but not currently public/reproducible in this repository. |

## Completed full benchmark

Completed `cv_10x10` methods:

- TSP
- k-TSP
- TSPDT / TSP-tree
- Random Rank Forest
- majority baseline
- glmnet elastic-net
- linear SVM
- Euclidean kNN
- CART/rpart tree
- random forest
- shallow XGBoost

Full result tables:

- `results/summary/cv_10x10_overall_method_summary.csv`
- `results/summary/cv_10x10_dataset_method_summary.csv`
- `docs/dataset_level_results.md`

## Python notebook candidates

The external wucc009 notebook probe identified the following Python-side candidates:

- TSP
- k-TSP+SVM
- REOs
- REOs+ML
- TSP+ML

These should be treated as `PROBE_ONLY` until converted into callable train/predict wrappers without hidden notebook state.

## R notebook candidates

The external wucc009 R notebook contains:

- GERs
- k-TSP
- TSPG

The current benchmark already includes one k-TSP implementation via switchBox. GERs and TSPG require separate inspection.

## Legacy / local methods

The following methods are important but not yet ready as public repository wrappers:

- EMTTree+RX
- RMCT / top-down multitest
- SVM+kTSP if the exact historical implementation differs from current k-TSP/SVM candidates
- RankCompV2 / RankCompV3
- TST / TSN
- FFR tree
- relational kNN / KNN+RRM

These are tracked explicitly rather than silently omitted.
