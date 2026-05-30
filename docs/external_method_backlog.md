# External method backlog

This file tracks external, optional, or later-stage methods that may be inspected after the core leakage-controlled benchmark is operational.

These methods are not automatically part of the primary benchmark. Each method must first pass a feasibility check and receive a clear status before being added to `config/methods.csv`.

Status labels:

- BACKLOG: noted for later inspection.
- PROBE_PLANNED: compatibility probe should be written.
- PASS_ENV: package/environment loads successfully.
- PASS_WRAPPER: wrapper runs on synthetic/minimal data.
- PARTIAL: runnable with important limitations.
- FAIL: attempted but not currently runnable.
- SKIPPED: excluded with explicit reason.

| candidate_id | status | language | source | notes |
|---|---:|---|---|---|
| ffr_tree_package | BACKLOG | TBD | TBD | User mentioned "FFR tree"; exact package/name/source must be verified later. |
| python_knn_relational | BACKLOG | Python | TBD | Python kNN-related packages/methods; inspect later for relational/rank-distance variants. |
| pyrrm_knn | BACKLOG | Python | pyRRM / related Python kNN methods | Relative Relation Metric / kNN-based relational methods. |
| wucc009_gene_pair_methods | BACKLOG | mixed | GitHub: wucc009/Implementation-and-comparison-of-gene-pair-methods | Candidate source for gene-pair method implementations; inspect after core wrappers are stable. |
| ranktreeensemble_rrf | BACKLOG | R/TBD | external | Candidate rank-tree / RRF-related method; verify exact implementation. |
| multiclassPairs | BACKLOG | R | external | Candidate if it fits binary/multiclass protocol and has stable API. |
| btsp | BACKLOG | TBD | external | Candidate only if runnable and methodologically relevant. |
| aurea | BACKLOG | TBD | external | Candidate legacy gene-pair framework; likely high compatibility risk. |
