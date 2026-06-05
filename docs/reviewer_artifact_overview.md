# Reviewer artifact overview

This file summarizes the reviewer-facing benchmark artifact.

## Repository purpose

The repository accompanies the manuscript **Rank-Based Relational Methods for Interpretable Biomedical AI: A Taxonomic Review** and provides a reproducibility-oriented benchmark package for the empirical comparison discussed in the manuscript.

## Primary protocol

| Item | Value |
|---|---|
| Protocol | `cv_5x5_f200` |
| Datasets | 8 public binary gene-expression datasets |
| Cross-validation | 5 repeats × 5 folds |
| Feature filtering | train-fold-only MAD |
| Number of features | 200 |
| Primary metric | balanced accuracy |
| Secondary metrics | macro-F1, MCC, accuracy |
| Completed final jobs | 3400 |
| Failed final jobs | 0 |

## Main reviewer-facing files

- `README.md`
- `QUICKSTART.md`
- `DATA.md`
- `METHODS.md`
- `RESULTS.md`
- `REPRODUCIBILITY.md`
- `figures/repo_benchmark_overview.png`
- `figures/repo_benchmark_overview.svg`
- `results/tables/final_overall_summary.csv`
- `results/tables/final_dataset_method_summary.csv`

## Caution

The benchmark should be interpreted as a reproducibility-oriented comparison under a common protocol. It is not an exhaustive tuning study and should not be used to claim universal superiority of relational methods.
