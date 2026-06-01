#!/usr/bin/env python3

from __future__ import annotations

import argparse
import time
from pathlib import Path

import pandas as pd
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score, balanced_accuracy_score, f1_score, matthews_corrcoef

from pyrrm import relative_relation_metric


ROOT = Path(".")
OUT = Path("results/pyrrm_jobs")


def load_final_dataset(dataset_id: str):
    x_path = ROOT / "data" / "final" / dataset_id / "X_features_x_samples.csv"
    y_path = ROOT / "data" / "final" / dataset_id / "y.csv"

    x_raw = pd.read_csv(x_path)
    y = pd.read_csv(y_path)

    feature_id = x_raw["feature_id"].astype(str)
    x = x_raw.drop(columns=["feature_id"])
    x.index = feature_id

    x = x.T
    x.index = x.index.astype(str)

    y["sample_id"] = y["sample_id"].astype(str)
    x = x.loc[y["sample_id"]]

    return x, y


def load_fold(protocol_id: str, dataset_id: str, repeat_id: int, fold_id: int):
    fold_path = ROOT / "data" / "folds" / f"{protocol_id}__{dataset_id}.csv"
    folds = pd.read_csv(fold_path)

    sub = folds[(folds["repeat_id"] == repeat_id) & (folds["fold_id"] == fold_id)]
    train_ids = sub.loc[sub["split"] == "train", "sample_id"].astype(str).tolist()
    test_ids = sub.loc[sub["split"] == "test", "sample_id"].astype(str).tolist()

    return train_ids, test_ids


def mad_filter_train_only(x_train: pd.DataFrame, x_test: pd.DataFrame, n_features: int):
    x_train_num = x_train.apply(pd.to_numeric, errors="coerce")
    x_test_num = x_test.apply(pd.to_numeric, errors="coerce")

    med = x_train_num.median(axis=0)
    x_train_num = x_train_num.fillna(med)
    x_test_num = x_test_num.fillna(med)

    mad = (x_train_num - med).abs().median(axis=0)
    selected = mad.sort_values(ascending=False).head(min(n_features, x_train_num.shape[1])).index.tolist()

    return x_train_num[selected], x_test_num[selected], selected


def compute_metrics(y_true, y_pred):
    return {
        "accuracy": accuracy_score(y_true, y_pred),
        "balanced_accuracy": balanced_accuracy_score(y_true, y_pred),
        "macro_f1": f1_score(y_true, y_pred, average="macro", zero_division=0),
        "mcc": matthews_corrcoef(y_true, y_pred),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", required=True)
    parser.add_argument("--protocol", default="cv_10x10")
    parser.add_argument("--repeat", type=int, required=True)
    parser.add_argument("--fold", type=int, required=True)
    parser.add_argument("--n_features", type=int, default=50)
    parser.add_argument("--k", type=int, default=3)
    args = parser.parse_args()

    dataset_id = args.dataset
    protocol_id = args.protocol
    repeat_id = args.repeat
    fold_id = args.fold
    n_features = args.n_features
    k = args.k
    method_id = f"pyrrm_knn{k}"

    job_id = f"{protocol_id}__{dataset_id}__{method_id}__r{repeat_id}__f{fold_id}"

    for sub in ["metrics", "predictions", "model_info", "runtime", "selected_features", "status", "logs"]:
        (OUT / sub).mkdir(parents=True, exist_ok=True)

    done_path = OUT / "status" / f"{job_id}.done"
    fail_path = OUT / "status" / f"{job_id}.fail"

    if done_path.exists():
        print(f"Job already done: {job_id}")
        return

    t0 = time.time()
    status = "FAIL"
    message = "unknown"

    try:
        x, y = load_final_dataset(dataset_id)
        train_ids, test_ids = load_fold(protocol_id, dataset_id, repeat_id, fold_id)

        y_series = pd.Series(y["class_label"].astype(str).values, index=y["sample_id"].astype(str).values)

        x_train = x.loc[train_ids]
        x_test = x.loc[test_ids]
        y_train = y_series.loc[train_ids]
        y_test = y_series.loc[test_ids]

        x_train, x_test, selected = mad_filter_train_only(x_train, x_test, n_features=n_features)

        t_fit0 = time.time()
        clf = KNeighborsClassifier(n_neighbors=k, metric=relative_relation_metric)
        clf.fit(x_train.values, y_train.values)
        t_fit1 = time.time()

        pred = clf.predict(x_test.values)
        t_pred1 = time.time()

        metrics = compute_metrics(y_test.values, pred)

        pd.DataFrame([{
            "dataset_id": dataset_id,
            "protocol_id": protocol_id,
            "method_id": method_id,
            "repeat_id": repeat_id,
            "fold_id": fold_id,
            "n_features": len(selected),
            "k": k,
            **metrics,
        }]).to_csv(OUT / "metrics" / f"{job_id}.csv", index=False)

        pd.DataFrame({
            "dataset_id": dataset_id,
            "protocol_id": protocol_id,
            "method_id": method_id,
            "repeat_id": repeat_id,
            "fold_id": fold_id,
            "sample_id": test_ids,
            "truth": y_test.values,
            "pred": pred,
        }).to_csv(OUT / "predictions" / f"{job_id}.csv", index=False)

        pd.DataFrame([{
            "dataset_id": dataset_id,
            "protocol_id": protocol_id,
            "method_id": method_id,
            "repeat_id": repeat_id,
            "fold_id": fold_id,
            "n_features_used": len(selected),
            "k": k,
            "metric": "pyrrm.relative_relation_metric",
            "notes": "Exact pyrrm relative_relation_metric used inside sklearn KNeighborsClassifier.",
        }]).to_csv(OUT / "model_info" / f"{job_id}.csv", index=False)

        pd.DataFrame([{
            "dataset_id": dataset_id,
            "protocol_id": protocol_id,
            "method_id": method_id,
            "repeat_id": repeat_id,
            "fold_id": fold_id,
            "train_seconds": t_fit1 - t_fit0,
            "predict_seconds": t_pred1 - t_fit1,
            "total_seconds": time.time() - t0,
        }]).to_csv(OUT / "runtime" / f"{job_id}.csv", index=False)

        pd.DataFrame({
            "dataset_id": dataset_id,
            "protocol_id": protocol_id,
            "method_id": method_id,
            "repeat_id": repeat_id,
            "fold_id": fold_id,
            "rank": list(range(1, len(selected) + 1)),
            "feature": selected,
        }).to_csv(OUT / "selected_features" / f"{job_id}.csv", index=False)

        status = "DONE"
        message = "ok"

    except Exception as e:
        status = "FAIL"
        message = str(e)

    pd.DataFrame([{
        "job_id": job_id,
        "dataset_id": dataset_id,
        "protocol_id": protocol_id,
        "method_id": method_id,
        "repeat_id": repeat_id,
        "fold_id": fold_id,
        "n_features": n_features,
        "k": k,
        "status": status,
        "message": message,
        "total_seconds": time.time() - t0,
    }]).to_csv(done_path if status == "DONE" else fail_path, index=False)

    print(job_id, status, message)

    if status != "DONE":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
