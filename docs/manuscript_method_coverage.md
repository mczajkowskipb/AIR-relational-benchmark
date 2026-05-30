# Manuscript method coverage

This document maps methods discussed or benchmarked in the manuscript to their status in the repository.

Coverage classes:

- REQUIRED_RUNNABLE: method appears in the experimental benchmark / Figure 4 and should be runnable through the repository pipeline.
- REQUIRED_STATUS_ONLY: method is discussed in taxonomy or qualitative tables but is not part of the experimental benchmark; repository should document availability/status.
- BACKLOG_OPTIONAL: candidate external method for later inspection; not required for the current revision.

Status labels:

- TODO: not yet probed.
- PASS_ENV: package/environment loads.
- PASS_WRAPPER: method trains and predicts on minimal/package data.
- PASS_SMOKE: method runs in the common benchmark smoke protocol.
- PASS_FULL: method completed the full benchmark.
- PARTIAL: runnable with limitations.
- FAIL: attempted but not runnable.
- SKIPPED: intentionally excluded with reason.

| manuscript_name | repo_method_id | coverage_class | current_status | candidate_source | notes |
|---|---|---:|---:|---|---|
| TSP | switchbox_tsp | REQUIRED_RUNNABLE | PASS_WRAPPER | switchBox | Functional kTSP package probe passed; 1-TSP wrapper still to be separated. |
| k-TSP | switchbox_ktsp | REQUIRED_RUNNABLE | PASS_WRAPPER | switchBox | Functional package probe passed. |
| TSPDT / TSP-tree | tspdt_bigtsp | REQUIRED_RUNNABLE | PASS_WRAPPER | BigTSP::tsp.tree | BigTSP installed from CRAN archive; predict requires response column in newdata. |
| Random Rank Forest / RRF | rrf_ranktreeensemble | REQUIRED_RUNNABLE | PASS_WRAPPER | ranktreeEnsemble | Probe next. |
| Rank-tree boosting | rtb_ranktreeensemble | REQUIRED_RUNNABLE | PASS_ENV | ranktreeEnsemble | Include if reported or if package exposes boosting variant clearly. |
| SVM+kTSP | svm_ktsp | REQUIRED_RUNNABLE | TODO | TBD | Requires exact historical implementation definition. |
| GER | ger | REQUIRED_RUNNABLE | TODO | TBD | Requires exact implementation used in manuscript. |
| RankCompV2 | rankcompv2 | REQUIRED_RUNNABLE | TODO | TBD | Check whether it belongs to Figure 4 benchmark or only review/status table. |
| KNN+RRM | knn_rrm | REQUIRED_RUNNABLE | TODO | pyRRM / Python TBD | Probe later; Python path should be isolated. |
| BTSP | btsp | REQUIRED_STATUS_ONLY | TODO | TBD | Only runnable if stable source exists. |
| EMTTree+RX | emttree_rx_status | REQUIRED_STATUS_ONLY | TODO | user legacy / paper | Not part of current Figure 4 unless explicitly added. |
| RMCT | rmct_status | REQUIRED_STATUS_ONLY | TODO | user legacy / paper | Not part of current Figure 4 unless explicitly added. |
| TST | tst_status | REQUIRED_STATUS_ONLY | TODO | literature / possible external | Status-only unless benchmarked. |
| TSN | tsn_status | REQUIRED_STATUS_ONLY | TODO | literature / possible external | Status-only unless benchmarked. |
| WTSP / WT-kTSP | weighted_tsp_status | REQUIRED_STATUS_ONLY | TODO | literature / possible custom | Status-only unless benchmarked. |
| iPAGE | ipage_status | REQUIRED_STATUS_ONLY | TODO | REO method | Different task axis; not directly same supervised benchmark. |
| RankComp | rankcomp_status | REQUIRED_STATUS_ONLY | TODO | REO method | Different task axis; not directly same supervised benchmark. |
| DIRAC | dirac_status | REQUIRED_STATUS_ONLY | TODO | pathway rank conservation | Different task axis; not directly same supervised benchmark. |
| wucc009 gene-pair methods | wucc009_gene_pair_methods | BACKLOG_OPTIONAL | TODO | GitHub external | Inspect after core required methods. |
| FFR tree package | ffr_tree_package | BACKLOG_OPTIONAL | TODO | TBD | Exact package/name must be clarified later. |
| Python kNN packages | python_knn_relational | BACKLOG_OPTIONAL | TODO | Python TBD | Inspect after R RXA core. |
