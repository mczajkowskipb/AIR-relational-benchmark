#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path

import pandas as pd

from method_gene_pair_python import fit_model, predict_model, compute_metrics


ROOT = Path(".")
OUT = Path("results/python_probe")
OUT.mkdir(parents=True, exist_ok=True)


def load_final_dataset(dataset_id: str):
    x_path = ROOT / "data" / "final" / dataset_id / "X_features_x_samples.csv"
    y_path = ROOT / "data" / "final" / dataset_id / "y.csv"

    x_raw = pd.read_csv(x_path)
    y = pd.read_csv(y_path)

    feature_id = x_raw["feature_id"].astype(str)
    x = x_raw.drop(columns=["feature_id"])
    x.index = feature_id

    # features x samples -> samples x features
    x = x.T
    x.index = x.index.astype(str)

    y["sample_id"] = y["sample_id"].astype(str)
    x = x.loc[y["sample_id"]]

    return x, y


def load_fold(dataset_id: str, repeat_id: int, fold_id: int):
    fold_path = ROOT / "data" / "folds" / f"smoke_2x2__{dataset_id}.csv"
    folds = pd.read_csv(fold_path)

    sub = folds[(folds["repeat_id"] == repeat_id) & (folds["fold_id"] == fold_id)]
    train_ids = sub.loc[sub["split"] == "train", "sample_id"].astype(str).tolist()
    test_ids = sub.loc[sub["split"] == "test", "sample_id"].astype(str).tolist()

    return train_ids, test_ids


def mad_filter_train_only(x_train: pd.DataFrame, x_test: pd.DataFrame, n_features: int = 100):
    mad = (x_train - x_train.median(axis=0)).abs().median(axis=0)
    selected = mad.sort_values(ascending=False).head(min(n_features, x_train.shape[1])).index.tolist()
    return x_train[selected], x_test[selected], selected


def run_one(dataset_id: str, method_id: str, repeat_id: int, fold_id: int):
    x, y = load_final_dataset(dataset_id)
    train_ids, test_ids = load_fold(dataset_id, repeat_id, fold_id)

    y_series = pd.Series(y["class_label"].astype(str).values, index=y["sample_id"].astype(str).values)

    x_train = x.loc[train_ids]
    x_test = x.loc[test_ids]
    y_train = y_series.loc[train_ids]
    y_test = y_series.loc[test_ids]

    x_train, x_test, selected = mad_filter_train_only(x_train, x_test, n_features=100)

    positive_label = sorted(y_train.unique())[1]

    model = fit_model(method_id, x_train, y_train, positive_label)
    pred, score = predict_model(model, x_test)
    metrics = compute_metrics(y_test, pred, score, positive_label)

    row = {
        "dataset_id": dataset_id,
        "method_id": method_id,
        "repeat_id": repeat_id,
        "fold_id": fold_id,
        "n_features": len(selected),
        "n_pairs": len(model.pairs),
        "positive_label": positive_label,
        **metrics,
        "notes": model.notes,
    }

    pred_df = pd.DataFrame({
        "dataset_id": dataset_id,
        "method_id": method_id,
        "repeat_id": repeat_id,
        "fold_id": fold_id,
        "sample_id": test_ids,
        "truth": y_test.values,
        "pred": pred,
        "score": score,
        "positive": positive_label,
    })

    return row, pred_df


def main():
    dataset_id = "GDS2771"
    methods = ["py_tsp", "py_tsp_svm", "py_tsp_rf", "py_reos", "py_reos_svm"]

    rows = []
    preds = []

    for method_id in methods:
        for repeat_id in [1, 2]:
            for fold_id in [1, 2]:
                print(f"Running {dataset_id} {method_id} r{repeat_id} f{fold_id}")
                row, pred_df = run_one(dataset_id, method_id, repeat_id, fold_id)
                rows.append(row)
                preds.append(pred_df)

    metrics = pd.DataFrame(rows)
    predictions = pd.concat(preds, ignore_index=True)

    metrics_path = OUT / "python_gene_pair_smoke_metrics.csv"
    pred_path = OUT / "python_gene_pair_smoke_predictions.csv"

    metrics.to_csv(metrics_path, index=False)
    predictions.to_csv(pred_path, index=False)

    summary = metrics.groupby("method_id")[["accuracy", "balanced_accuracy", "macro_f1", "mcc"]].mean().reset_index()
    summary_path = OUT / "python_gene_pair_smoke_summary.csv"
    summary.to_csv(summary_path, index=False)

    print("=== Python gene-pair smoke summary ===")
    print(summary)

    print("Written:", metrics_path)
    print("Written:", pred_path)
    print("Written:", summary_path)


if __name__ == "__main__":
    main()
