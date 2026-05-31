#!/usr/bin/env python3

from pathlib import Path
import pandas as pd

protocol_id = "cv_10x10"
methods = ["py_tsp", "py_tsp_svm", "py_tsp_rf", "py_reos", "py_reos_svm"]

out_dir = Path("results/python_jobs")
out_dir.mkdir(parents=True, exist_ok=True)

fold_summary = pd.read_csv(f"data/manifests/{protocol_id}_fold_summary.csv")

rows = []
k = 0

for dataset_id in fold_summary["dataset_id"]:
    folds = pd.read_csv(f"data/folds/{protocol_id}__{dataset_id}.csv")
    combos = folds[["repeat_id", "fold_id"]].drop_duplicates()

    for method_id in methods:
        for _, row in combos.iterrows():
            k += 1
            rows.append({
                "job_index": k,
                "protocol_id": protocol_id,
                "dataset_id": dataset_id,
                "method_id": method_id,
                "repeat_id": int(row["repeat_id"]),
                "fold_id": int(row["fold_id"]),
                "n_features": 100,
            })

grid = pd.DataFrame(rows)

grid["command"] = (
    ".venv/bin/python scripts/python/03_run_single_gene_pair_job.py"
    + " --protocol=" + grid["protocol_id"]
    + " --dataset=" + grid["dataset_id"]
    + " --method=" + grid["method_id"]
    + " --repeat=" + grid["repeat_id"].astype(str)
    + " --fold=" + grid["fold_id"].astype(str)
    + " --n_features=" + grid["n_features"].astype(str)
)

grid_path = out_dir / "cv_10x10_python_gene_pair_grid.csv"
cmd_path = out_dir / "cv_10x10_python_gene_pair_commands.txt"

grid.to_csv(grid_path, index=False)
cmd_path.write_text("\n".join(grid["command"]) + "\n", encoding="utf-8")

print("Jobs:", len(grid))
print("Written:", grid_path)
print("Written:", cmd_path)
