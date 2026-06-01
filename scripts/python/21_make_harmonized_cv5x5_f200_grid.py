#!/usr/bin/env python3

from pathlib import Path
import pandas as pd

protocol_id = "cv_5x5_f200"
n_features = 200

out_dir = Path("results/harmonized_cv5x5_f200")
out_dir.mkdir(parents=True, exist_ok=True)

fold_summary = pd.read_csv(f"data/manifests/{protocol_id}_fold_summary.csv")

r_methods = [
    "majority",
    "switchbox_tsp",
    "switchbox_ktsp",
    "tspdt_bigtsp",
    "rrf_ranktreeensemble",
    "glmnet_enet",
    "svm_linear",
    "knn_euclidean",
    "rpart_tree",
    "ranger_rf",
    "xgboost_shallow",
]

py_gene_pair_methods = [
    "py_tsp",
    "py_tsp_svm",
    "py_tsp_rf",
    "py_reos",
    "py_reos_svm",
]

rows = []
job_index = 0

for dataset_id in fold_summary["dataset_id"]:
    folds = pd.read_csv(f"data/folds/{protocol_id}__{dataset_id}.csv")
    combos = folds[["repeat_id", "fold_id"]].drop_duplicates()

    for method_id in r_methods:
        for _, row in combos.iterrows():
            job_index += 1
            rows.append({
                "job_index": job_index,
                "protocol_id": protocol_id,
                "dataset_id": dataset_id,
                "method_id": method_id,
                "family": "R",
                "repeat_id": int(row["repeat_id"]),
                "fold_id": int(row["fold_id"]),
                "n_features": n_features,
                "command": (
                    "RRF_NTREE=100 Rscript scripts/10_run_single_job.R"
                    f" --protocol={protocol_id}"
                    f" --dataset={dataset_id}"
                    f" --method={method_id}"
                    f" --repeat={int(row['repeat_id'])}"
                    f" --fold={int(row['fold_id'])}"
                    f" --n_features={n_features}"
                ),
            })

    for method_id in py_gene_pair_methods:
        for _, row in combos.iterrows():
            job_index += 1
            rows.append({
                "job_index": job_index,
                "protocol_id": protocol_id,
                "dataset_id": dataset_id,
                "method_id": method_id,
                "family": "python_gene_pair",
                "repeat_id": int(row["repeat_id"]),
                "fold_id": int(row["fold_id"]),
                "n_features": n_features,
                "command": (
                    ".venv/bin/python scripts/python/03_run_single_gene_pair_job.py"
                    f" --protocol={protocol_id}"
                    f" --dataset={dataset_id}"
                    f" --method={method_id}"
                    f" --repeat={int(row['repeat_id'])}"
                    f" --fold={int(row['fold_id'])}"
                    f" --n_features={n_features}"
                ),
            })

    # pyrrm relational kNN, k=5, also f200
    for _, row in combos.iterrows():
        job_index += 1
        rows.append({
            "job_index": job_index,
            "protocol_id": protocol_id,
            "dataset_id": dataset_id,
            "method_id": "pyrrm_knn5",
            "family": "pyrrm",
            "repeat_id": int(row["repeat_id"]),
            "fold_id": int(row["fold_id"]),
            "n_features": n_features,
            "command": (
                ".venv/bin/python scripts/python/07_run_single_pyrrm_job.py"
                f" --protocol={protocol_id}"
                f" --dataset={dataset_id}"
                f" --repeat={int(row['repeat_id'])}"
                f" --fold={int(row['fold_id'])}"
                f" --n_features={n_features}"
                " --k=5"
            ),
        })

grid = pd.DataFrame(rows)

grid_path = out_dir / "cv_5x5_f200_job_grid.csv"
cmd_path = out_dir / "cv_5x5_f200_commands.txt"

grid.to_csv(grid_path, index=False)
cmd_path.write_text("\n".join(grid["command"]) + "\n", encoding="utf-8")

print("Jobs:", len(grid))
print("Written:", grid_path)
print("Written:", cmd_path)
print(grid["family"].value_counts())
