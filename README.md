# AIR Relational Benchmark

This repository accompanies a manuscript on relational and rank-based methods for interpretable biomedical machine learning.

The repository provides benchmark-ready biomedical binary classification datasets, fixed cross-validation folds, R and Python wrappers for relational/rank-based methods and reference ML baselines, final benchmark summaries, and scripts to regenerate the main result tables and figures.

## Primary benchmark

Protocol: `cv_5x5_f200`

- 8 binary biomedical datasets
- 5 repeats x 5 folds
- train-only MAD feature filtering to 200 features
- identical folds for all methods
- primary metric: balanced accuracy
- secondary metrics: macro-F1, MCC, accuracy
- final completed jobs: 3400
- final failed jobs in the completed benchmark: 0

TSPDT/BigTSP at f200 requires increasing R's protection stack:

```bash
Rscript --max-ppsize=500000
```

## Main files

| File / directory | Purpose |
|---|---|
| `QUICKSTART.md` | Minimal instructions for reproducing summaries and figures |
| `DATA.md` | Dataset organization and provenance notes |
| `METHODS.md` | Methods included in the benchmark |
| `RESULTS.md` | Final benchmark result overview |
| `REPRODUCIBILITY.md` | Reproducibility protocol and environment notes |
| `data/final/` | Final benchmark matrices |
| `data/folds/` | Fixed CV fold definitions |
| `results/summary/` | Final CSV summaries |
| `figures/` | Manuscript-ready figures |
| `scripts/final/` | Final user-facing scripts |
| `scripts/dev/` | Exploratory/debug/probe scripts retained for transparency |

## Quick use

Check the environment:

```bash
bash scripts/final/00_setup_check.sh
```

Regenerate final result summaries from completed per-fold outputs:

```bash
bash scripts/final/05_collect_final_results.sh
```

Regenerate figures:

```bash
.venv/bin/python scripts/final/06_make_figures.py
```

## Main result files

```text
results/summary/harmonized_cv5x5_f200_complete_overall_summary.csv
results/summary/harmonized_cv5x5_f200_complete_dataset_method_summary.csv
results/summary/harmonized_cv5x5_f200_complete_method_ranks_by_dataset.csv
results/summary/harmonized_cv5x5_f200_complete_best_method_by_dataset.csv
results/summary/harmonized_cv5x5_f200_complete_best_relational_method_by_dataset.csv
```

## Scope

The benchmark is not intended to prove universal superiority of any method. It is a compact, harmonized demonstration of relational/rank-based and reference methods under a shared feature-universe protocol.
