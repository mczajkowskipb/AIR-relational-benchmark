# Binary label mapping decisions

This document records the binary class definitions used for the eight-dataset AIR relational benchmark.

The mappings were chosen to reproduce the legacy eight-dataset benchmark structure and preserve the instance counts reported in the manuscript. Some datasets are disease-vs-control contrasts, while others are phenotype or clinical endpoint contrasts. These choices are explicitly recorded in `config/label_mapping.csv`.

The goal is not to claim that all datasets represent the same biological task. The goal is to provide a transparent, reproducible, leakage-controlled reconstruction of the benchmark.

## Dataset-level decisions

| dataset_id | benchmark description | positive class | negative class | mapping note |
|---|---|---|---|---|
| GDS2771 | Lung cancer | cancer | no_cancer | `cancer` and `suspect cancer` are treated as positive to preserve the legacy sample count. |
| GSE10072 | Lung adenocarcinoma | tumor | normal | Adenocarcinoma of the lung vs normal lung tissue. |
| GSE17920 | Hodgkin lymphoma | relapse | no_relapse | Any recorded relapse type (`LATE`, `REFRACTORY`, `EARLY`) vs no relapse marker `_`. |
| GSE19804 | Lung cancer | tumor | normal | Lung cancer vs paired adjacent normal tissue. |
| GSE25837 | Chronic loneliness | lonely | not_lonely | `lonely: 1` vs `lonely: 0`. |
| GSE27272 | Impact of tobacco smoke | smoker | non_smoker | Smoker vs non-smoker across tissue sources. |
| GSE3365 | Inflammatory bowel disease | ibd | normal | Crohn's Disease plus Ulcerative Colitis vs Normal. |
| GSE6613 | Parkinson's disease | parkinson | control | Parkinson's disease vs neurological disease control plus healthy control. |

## Reviewer-facing note

All class mappings are encoded in `config/label_mapping.csv` and are used by `scripts/03_prepare_final_datasets.R`. The benchmark does not infer labels automatically during model fitting. This avoids hidden sample selection and makes the binary task definition auditable.
