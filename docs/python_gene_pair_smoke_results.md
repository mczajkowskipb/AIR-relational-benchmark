# Python gene-pair smoke results

This document summarizes the first Python-side gene-pair smoke test.

Implemented benchmark-style wrappers:

- `py_tsp`
- `py_tsp_svm`
- `py_tsp_rf`
- `py_reos`
- `py_reos_svm`

These wrappers are inspired by the external wucc009 notebook sections:

- TSP
- k-TSP+SVM
- REOs
- REOs+ML
- TSP+ML

They are not a verbatim notebook execution. The notebook contains manual file paths, intermediate CSVs, and notebook-state-dependent steps. The wrappers instead implement the same broad logic in a clean train/predict interface compatible with the AIR benchmark.

Initial smoke result file:

- `results/python_probe/python_gene_pair_smoke_summary.csv`

Status:

- smoke-level only
- not yet included in full `cv_10x10`
