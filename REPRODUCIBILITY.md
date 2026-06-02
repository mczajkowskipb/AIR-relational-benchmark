# Reproducibility

## Primary benchmark

The primary benchmark is:

```text
cv_5x5_f200
```

with:

- 8 datasets,
- 5 repeats x 5 folds,
- train-only MAD filtering to 200 features,
- identical folds for all methods.

## Check environment

```bash
bash scripts/final/00_setup_check.sh
```

## Reproduce final summaries

If per-fold job outputs are already available:

```bash
bash scripts/final/05_collect_final_results.sh
```

## Reproduce figures

```bash
.venv/bin/python scripts/final/06_make_figures.py
```

## Full rerun

The full benchmark may take several hours.

```bash
bash scripts/final/04_run_harmonized_cv5x5_f200.sh
```

The TSPDT part must be run with:

```bash
Rscript --max-ppsize=500000
```

This is handled by the final benchmark runner.

## Development scripts

Exploratory probes and debugging scripts are retained under:

```text
scripts/dev/
```

They are not required for reproducing the final manuscript tables.
