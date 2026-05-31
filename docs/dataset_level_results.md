# Dataset-level cv10x10 results

This document reports dataset-level results for the full `cv_10x10` benchmark.

Aggregation across all datasets is useful as a compact overview, but it hides strong dataset-specific behavior. Therefore, the tables below should be used when discussing method behavior in the manuscript or response to reviewers.

## Balanced accuracy by dataset

| dataset_id | majority | switchbox_tsp | switchbox_ktsp | tspdt_bigtsp | rrf_ranktreeensemble | glmnet_enet | svm_linear | knn_euclidean | rpart_tree | ranger_rf | xgboost_shallow |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GDS2771 | 0.500 | 0.609 | 0.658 | 0.663 | 0.579 | 0.713 | 0.712 | 0.702 | 0.617 | 0.737 | 0.683 |
| GSE10072 | 0.500 | 0.962 | 0.970 | 0.935 | 0.572 | 0.977 | 0.975 | 0.980 | 0.939 | 0.981 | 0.952 |
| GSE17920 | 0.500 | 0.558 | 0.505 | 0.553 | 0.613 | 0.557 | 0.559 | 0.550 | 0.663 | 0.673 | 0.650 |
| GSE19804 | 0.500 | 0.946 | 0.938 | 0.908 | 0.898 | 0.953 | 0.917 | 0.947 | 0.922 | 0.953 | 0.943 |
| GSE25837 | 0.500 | 0.566 | 0.349 | 0.453 | 0.488 | 0.500 | 0.528 | 0.466 | 0.429 | 0.498 | 0.482 |
| GSE27272 | 0.500 | 0.504 | 0.432 | 0.458 | 0.481 | 0.497 | 0.545 | 0.467 | 0.515 | 0.504 | 0.502 |
| GSE3365 | 0.500 | 0.830 | 0.824 | 0.839 | 0.783 | 0.942 | 0.930 | 0.812 | 0.823 | 0.841 | 0.858 |
| GSE6613 | 0.500 | 0.495 | 0.614 | 0.556 | 0.470 | 0.519 | 0.552 | 0.597 | 0.484 | 0.533 | 0.525 |

## Macro-F1 by dataset

| dataset_id | majority | switchbox_tsp | switchbox_ktsp | tspdt_bigtsp | rrf_ranktreeensemble | glmnet_enet | svm_linear | knn_euclidean | rpart_tree | ranger_rf | xgboost_shallow |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GDS2771 | 0.347 | 0.598 | 0.651 | 0.659 | 0.543 | 0.709 | 0.708 | 0.698 | 0.609 | 0.733 | 0.678 |
| GSE10072 | 0.351 | 0.961 | 0.970 | 0.933 | 0.528 | 0.977 | 0.976 | 0.981 | 0.938 | 0.982 | 0.952 |
| GSE17920 | 0.415 | 0.525 | 0.481 | 0.544 | 0.592 | 0.520 | 0.546 | 0.532 | 0.660 | 0.681 | 0.654 |
| GSE19804 | 0.333 | 0.945 | 0.937 | 0.907 | 0.895 | 0.953 | 0.916 | 0.946 | 0.921 | 0.952 | 0.942 |
| GSE25837 | 0.430 | 0.454 | 0.329 | 0.443 | 0.436 | 0.430 | 0.505 | 0.443 | 0.410 | 0.435 | 0.422 |
| GSE27272 | 0.412 | 0.435 | 0.384 | 0.450 | 0.455 | 0.414 | 0.538 | 0.423 | 0.504 | 0.461 | 0.424 |
| GSE3365 | 0.401 | 0.795 | 0.809 | 0.837 | 0.736 | 0.937 | 0.925 | 0.791 | 0.825 | 0.847 | 0.860 |
| GSE6613 | 0.343 | 0.451 | 0.583 | 0.546 | 0.398 | 0.428 | 0.536 | 0.582 | 0.472 | 0.519 | 0.510 |

## MCC by dataset

| dataset_id | majority | switchbox_tsp | switchbox_ktsp | tspdt_bigtsp | rrf_ranktreeensemble | glmnet_enet | svm_linear | knn_euclidean | rpart_tree | ranger_rf | xgboost_shallow |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GDS2771 | 0.000 | 0.234 | 0.330 | 0.335 | 0.182 | 0.441 | 0.433 | 0.424 | 0.243 | 0.503 | 0.384 |
| GSE10072 | 0.000 | 0.930 | 0.945 | 0.877 | 0.141 | 0.960 | 0.957 | 0.965 | 0.887 | 0.967 | 0.912 |
| GSE17920 | 0.000 | 0.108 | 0.010 | 0.116 | 0.223 | 0.157 | 0.115 | 0.122 | 0.353 | 0.458 | 0.410 |
| GSE19804 | 0.000 | 0.897 | 0.883 | 0.828 | 0.814 | 0.913 | 0.846 | 0.898 | 0.852 | 0.911 | 0.892 |
| GSE25837 | 0.000 | 0.126 | -0.277 | -0.085 | -0.024 | 0.000 | 0.036 | -0.068 | -0.149 | -0.006 | -0.044 |
| GSE27272 | 0.000 | 0.018 | -0.133 | -0.086 | -0.041 | -0.006 | 0.093 | -0.094 | 0.041 | 0.018 | 0.006 |
| GSE3365 | 0.000 | 0.639 | 0.655 | 0.697 | 0.560 | 0.885 | 0.864 | 0.615 | 0.680 | 0.721 | 0.744 |
| GSE6613 | 0.000 | -0.010 | 0.261 | 0.116 | -0.078 | 0.041 | 0.111 | 0.206 | -0.036 | 0.066 | 0.053 |

## Best method per dataset by balanced accuracy

| dataset_id | method_id | balanced_accuracy | accuracy | macro_f1 | mcc |
| --- | --- | --- | --- | --- | --- |
| GDS2771 | ranger_rf | 0.737 | 0.745 | 0.733 | 0.503 |
| GSE10072 | ranger_rf | 0.981 | 0.982 | 0.982 | 0.967 |
| GSE17920 | ranger_rf | 0.673 | 0.800 | 0.681 | 0.458 |
| GSE19804 | glmnet_enet | 0.953 | 0.953 | 0.953 | 0.913 |
| GSE25837 | switchbox_tsp | 0.566 | 0.482 | 0.454 | 0.126 |
| GSE27272 | svm_linear | 0.545 | 0.637 | 0.538 | 0.093 |
| GSE3365 | glmnet_enet | 0.942 | 0.945 | 0.937 | 0.885 |
| GSE6613 | switchbox_ktsp | 0.614 | 0.606 | 0.583 | 0.261 |

## Best relational method per dataset by balanced accuracy

| dataset_id | method_id | balanced_accuracy | accuracy | macro_f1 | mcc |
| --- | --- | --- | --- | --- | --- |
| GDS2771 | tspdt_bigtsp | 0.663 | 0.665 | 0.659 | 0.335 |
| GSE10072 | switchbox_ktsp | 0.970 | 0.971 | 0.970 | 0.945 |
| GSE17920 | rrf_ranktreeensemble | 0.613 | 0.649 | 0.592 | 0.223 |
| GSE19804 | switchbox_tsp | 0.946 | 0.946 | 0.945 | 0.897 |
| GSE25837 | switchbox_tsp | 0.566 | 0.482 | 0.454 | 0.126 |
| GSE27272 | switchbox_tsp | 0.504 | 0.459 | 0.435 | 0.018 |
| GSE3365 | tspdt_bigtsp | 0.839 | 0.860 | 0.837 | 0.697 |
| GSE6613 | switchbox_ktsp | 0.614 | 0.606 | 0.583 | 0.261 |

## Interpretation note

The classical baselines are lightweight, non-nested reference models. They should be described as reviewer-facing context rather than as fully optimized state-of-the-art baselines.

The relational methods should be interpreted primarily as compact, transparent, within-sample relation-based classifiers. Their value is not only aggregate predictive performance, but also model simplicity and interpretability.
