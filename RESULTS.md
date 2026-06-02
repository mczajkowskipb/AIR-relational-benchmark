# Results

## Primary result table

The primary completed benchmark summary is:

```text
results/summary/harmonized_cv5x5_f200_complete_overall_summary.csv
```

Dataset-level results are in:

```text
results/summary/harmonized_cv5x5_f200_complete_dataset_method_summary.csv
```

## Primary protocol

```text
Protocol: cv_5x5_f200
Datasets: 8
Repeats: 5
Folds: 5
Feature filter: train-only MAD to 200 features
Primary metric: balanced accuracy
Final completed jobs: 3400
Final failed jobs: 0
```

## Technical note on TSPDT

BigTSP/TSPDT at f200 initially failed under default R settings due to R protection-stack limitations. The final f200 rerun succeeded with:

```bash
Rscript --max-ppsize=500000
```

The final completed benchmark therefore includes TSPDT at f200.
