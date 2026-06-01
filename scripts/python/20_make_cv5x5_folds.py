#!/usr/bin/env python3

from pathlib import Path
import pandas as pd
from sklearn.model_selection import StratifiedKFold

protocol_id = "cv_5x5_f200"
data_dir = Path("data/final")
fold_dir = Path("data/folds")
manifest_dir = Path("data/manifests")

fold_dir.mkdir(parents=True, exist_ok=True)
manifest_dir.mkdir(parents=True, exist_ok=True)

dataset_ids = sorted([p.name for p in data_dir.iterdir() if p.is_dir()])

summary_rows = []

for dataset_id in dataset_ids:
    y_path = data_dir / dataset_id / "y.csv"
    y = pd.read_csv(y_path)
    y["sample_id"] = y["sample_id"].astype(str)
    y["class_label"] = y["class_label"].astype(str)

    rows = []

    for repeat_id in range(1, 6):
        skf = StratifiedKFold(
            n_splits=5,
            shuffle=True,
            random_state=20260601 + repeat_id
        )

        for fold_id, (train_idx, test_idx) in enumerate(
            skf.split(y["sample_id"], y["class_label"]),
            start=1
        ):
            for idx in train_idx:
                rows.append({
                    "dataset_id": dataset_id,
                    "sample_id": y.iloc[idx]["sample_id"],
                    "class_label": y.iloc[idx]["class_label"],
                    "repeat_id": repeat_id,
                    "fold_id": fold_id,
                    "split": "train",
                })

            for idx in test_idx:
                rows.append({
                    "dataset_id": dataset_id,
                    "sample_id": y.iloc[idx]["sample_id"],
                    "class_label": y.iloc[idx]["class_label"],
                    "repeat_id": repeat_id,
                    "fold_id": fold_id,
                    "split": "test",
                })

    out = pd.DataFrame(rows)
    out_path = fold_dir / f"{protocol_id}__{dataset_id}.csv"
    out.to_csv(out_path, index=False)

    class_counts = y["class_label"].value_counts().to_dict()

    summary_rows.append({
        "dataset_id": dataset_id,
        "protocol_id": protocol_id,
        "n_samples": len(y),
        "n_repeats": 5,
        "n_folds": 5,
        "class_counts": ";".join(f"{k}:{v}" for k, v in class_counts.items()),
        "fold_file": str(out_path),
    })

summary = pd.DataFrame(summary_rows)
summary.to_csv(manifest_dir / f"{protocol_id}_fold_summary.csv", index=False)

print("Datasets:", len(dataset_ids))
print("Written:", manifest_dir / f"{protocol_id}_fold_summary.csv")
