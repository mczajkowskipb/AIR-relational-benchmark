# AIR Relational Benchmark

Reproducible benchmark repository for rank-based, pairwise and relational learning methods used in the Artificial Intelligence Review manuscript.

The repository is designed to support two related goals:

1. Reproduce the manuscript's legacy benchmark on eight GEO datasets.
2. Provide a revised leakage-controlled benchmark using shared folds, train-fold-only preprocessing, classical ML baselines, relational methods, per-fold predictions, metrics, runtime, and model-size summaries.

## Current status

This repository is under active construction. Methods are tracked in `config/methods.csv` and documented in `docs/method_status.md`.

## Benchmark datasets

The initial benchmark uses eight GEO datasets:

- GDS2771
- GSE10072
- GSE17920
- GSE19804
- GSE25837
- GSE27272
- GSE3365
- GSE6613

## Main protocols

- `config/protocols/smoke_test.yml`
- `config/protocols/legacy_figure4_reproduction.yml`
- `config/protocols/revised_mad_top1000.yml`

## Leakage control

Feature filtering and preprocessing must be fitted only on the training part of each split. The test fold must not influence feature selection, scaling, imputation, parameter tuning, or model fitting.

## Repository status

Do not interpret the presence of a method file as evidence that the method is already validated. Check `config/methods.csv` and `docs/method_status.md`.
