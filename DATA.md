# Data

## Dataset organization

The benchmark uses 8 binary biomedical gene-expression datasets:

```text
GDS2771
GSE10072
GSE17920
GSE19804
GSE25837
GSE27272
GSE3365
GSE6613
```

Final benchmark-ready matrices are expected under:

```text
data/final/<DATASET_ID>/
```

Fixed cross-validation folds are under:

```text
data/folds/
```

Dataset and fold manifests are under:

```text
data/manifests/
```

## Primary preprocessing

The primary benchmark protocol is `cv_5x5_f200`.

For every train/test fold:

1. feature filtering is fitted only on the training split,
2. MAD filtering selects up to 200 features,
3. imputation/scaling, when required by a method, is fitted only on the training split,
4. the learned preprocessing is applied to the corresponding test split.

## Raw and processed data

The repository may contain:

```text
data/raw/        original/source data, if redistribution is allowed
data/processed/  intermediate processed files
data/final/      final benchmark matrices used by the scripts
```

If raw data cannot be redistributed directly, `data/raw/README.md` and this file should provide source accessions and reconstruction instructions.
