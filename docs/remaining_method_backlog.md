# Remaining method backlog

This document tracks methods that are mentioned in the manuscript, Figure 4, review tables, or related AIR/RXA discussions but are not yet part of the completed `cv_10x10` benchmark.

The purpose of this file is transparency: methods are not silently omitted. Each candidate is tracked with a planned action or reason for postponement.

## Current completed benchmark methods

Completed full `cv_10x10` protocol:

- majority
- switchbox_tsp
- switchbox_ktsp
- tspdt_bigtsp
- rrf_ranktreeensemble
- glmnet_enet
- svm_linear
- knn_euclidean
- rpart_tree
- ranger_rf
- xgboost_shallow

## Remaining relational / rank-based candidates

| method / family | likely source | language | priority | current action |
|---|---|---:|---:|---|
| Rank-tree boosting | `ranktreeEnsemble::rboost` | R | medium | Environment available; functional/full benchmark optional unless explicitly needed for Figure 4 coverage. |
| KNN+RRM / relational kNN | pyRRM or custom wrapper | Python/R | high | Needs isolated Python probe and exact definition of distance/encoding. |
| Python kNN rank packages | external Python packages | Python | medium | Need package discovery and reproducibility check. |
| wucc009 gene-pair methods | GitHub `wucc009/Implementation-and-comparison-of-gene-pair-methods` | mixed | high | Inspect repository; identify runnable methods overlapping with Figure 4. |
| SVM+kTSP | historical implementation TBD | R/Python/TBD | medium | Need exact implementation definition before benchmarking. |
| GER | implementation TBD | TBD | medium | Need source/definition used in previous comparison. |
| RankCompV2 / RankComp family | RankComp implementation | R/TBD | low/medium | Usually task differs from simple supervised benchmark; document carefully before inclusion. |
| FFR tree package | exact package name TBD | TBD | low/medium | Needs package identification. |
| EMTTree+RX | user legacy C++ | C++ | status-only for now | Not part of current public benchmark unless converted into reproducible wrapper. |
| RMCT | user legacy CUDA/C++ | C++/CUDA | status-only for now | Not part of current public benchmark unless converted into reproducible wrapper. |
| BTSP / weighted TSP variants | literature / external TBD | TBD | low | Add only if a stable implementation is found. |

## Policy for adding remaining methods

A method should be added to the full benchmark only if:

1. the original or a faithful implementation is available;
2. the input/output interface can be made reproducible;
3. label handling and train-only preprocessing remain unchanged;
4. the method can be run from the repository without hidden manual steps;
5. its task matches the supervised binary benchmark.

Methods that fail these criteria should be documented as `PARTIAL`, `SKIPPED`, or `STATUS_ONLY`, not silently removed.
