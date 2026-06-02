# Quick start

## 1. Check the environment

```bash
bash scripts/final/00_setup_check.sh
```

## 2. Regenerate final summaries from completed job outputs

```bash
bash scripts/final/05_collect_final_results.sh
```

Expected output includes:

```text
results/summary/harmonized_cv5x5_f200_complete_overall_summary.csv
results/summary/harmonized_cv5x5_f200_complete_dataset_method_summary.csv
```

## 3. Regenerate figures

```bash
.venv/bin/python scripts/final/06_make_figures.py
```

Expected output includes:

```text
figures/Fig4_method_family_balanced_accuracy.svg
figures/Fig_overall_all_methods.svg
figures/Fig_dataset_level_heatmap.svg
```

## 4. Full benchmark rerun

A full rerun is computationally heavier and is not required to inspect the final results.

```bash
bash scripts/final/04_run_harmonized_cv5x5_f200.sh
```
