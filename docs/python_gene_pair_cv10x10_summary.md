# Python gene-pair cv10x10 benchmark summary

This document summarizes the full Python gene-pair benchmark.

Implemented benchmark-style wrappers:

- `py_tsp`
- `py_tsp_svm`
- `py_tsp_rf`
- `py_reos`
- `py_reos_svm`

These methods are benchmark-compatible wrappers inspired by the external wucc009 notebook sections. They are not a verbatim notebook execution because the notebook depends on manual file paths, intermediate CSVs, and notebook state.

Protocol:

- 8 datasets
- 10 repeats
- 10 folds per repeat
- 5 Python gene-pair methods
- 4000 total jobs
- 4000 completed jobs
- 0 failed jobs

## Overall summary

| method_id | mean balanced accuracy | mean macro-F1 | mean MCC | mean n pairs |
|---|---:|---:|---:|---:|
| py_tsp_rf | 0.6876 | 0.6658 | 0.3861 | 50.0000 |
| py_reos_svm | 0.6777 | 0.6711 | 0.3621 | 25.0000 |
| py_tsp_svm | 0.6759 | 0.6692 | 0.3585 | 25.0000 |
| py_tsp | 0.6613 | 0.6398 | 0.3256 | 1.0000 |
| py_reos | 0.6583 | 0.6315 | 0.3252 | 25.0000 |

## Best Python gene-pair method per dataset

| dataset_id | method_id | balanced accuracy | macro-F1 | MCC |
|---|---|---:|---:|---:|
| GDS2771 | py_reos_svm | 0.6890 | 0.6860 | 0.3878 |
| GSE10072 | py_tsp_rf | 0.9696 | 0.9697 | 0.9450 |
| GSE17920 | py_reos_svm | 0.5915 | 0.5806 | 0.1945 |
| GSE19804 | py_reos | 0.9425 | 0.9417 | 0.8928 |
| GSE25837 | py_tsp_rf | 0.4836 | 0.4254 | -0.0405 |
| GSE27272 | py_tsp_rf | 0.4856 | 0.4131 | -0.0497 |
| GSE3365 | py_tsp | 0.8654 | 0.8296 | 0.7061 |
| GSE6613 | py_reos | 0.5647 | 0.5151 | 0.1714 |

## Interpretation note

These Python methods expand Figure 4 / method-coverage support. They should be reported as additional benchmark-compatible gene-pair wrappers inspired by the external notebook, not as exact reproductions of the original notebook workflow.