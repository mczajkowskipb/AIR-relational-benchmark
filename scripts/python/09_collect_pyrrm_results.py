#!/usr/bin/env python3

from pathlib import Path
import pandas as pd

IN = Path("results/pyrrm_jobs")
OUT = Path("results/summary")
DOCS = Path("docs")

OUT.mkdir(parents=True, exist_ok=True)
DOCS.mkdir(parents=True, exist_ok=True)


def read_many(path, pattern="*.csv"):
    files = sorted(Path(path).glob(pattern))
    if not files:
        raise SystemExit(f"No files found in {path}")
    return pd.concat((pd.read_csv(f) for f in files), ignore_index=True)


def main():
    metrics = read_many(IN / "metrics")
    runtime = read_many(IN / "runtime")
    model_info = read_many(IN / "model_info")
    done_files = sorted((IN / "status").glob("*.done"))
    fail_files = sorted((IN / "status").glob("*.fail"))

    status = pd.concat((pd.read_csv(f) for f in done_files), ignore_index=True)

    print("Metric files:", len(list((IN / "metrics").glob("*.csv"))))
    print("Runtime files:", len(list((IN / "runtime").glob("*.csv"))))
    print("Model info files:", len(list((IN / "model_info").glob("*.csv"))))
    print("Done files:", len(done_files))
    print("Fail files:", len(fail_files))

    dataset_method = (
        metrics
        .groupby(["dataset_id", "method_id"], as_index=False)
        .agg(
            accuracy_mean=("accuracy", "mean"),
            accuracy_std=("accuracy", "std"),
            balanced_accuracy_mean=("balanced_accuracy", "mean"),
            balanced_accuracy_std=("balanced_accuracy", "std"),
            macro_f1_mean=("macro_f1", "mean"),
            macro_f1_std=("macro_f1", "std"),
            mcc_mean=("mcc", "mean"),
            mcc_std=("mcc", "std"),
            n_features_mean=("n_features", "mean"),
            k_mean=("k", "mean"),
        )
    )

    overall = (
        dataset_method
        .groupby("method_id", as_index=False)
        .agg(
            n_datasets=("dataset_id", "count"),
            mean_accuracy=("accuracy_mean", "mean"),
            mean_balanced_accuracy=("balanced_accuracy_mean", "mean"),
            mean_macro_f1=("macro_f1_mean", "mean"),
            mean_mcc=("mcc_mean", "mean"),
            sd_balanced_accuracy_across_datasets=("balanced_accuracy_mean", "std"),
            sd_macro_f1_across_datasets=("macro_f1_mean", "std"),
            sd_mcc_across_datasets=("mcc_mean", "std"),
            mean_n_features=("n_features_mean", "mean"),
            mean_k=("k_mean", "mean"),
        )
        .sort_values("mean_balanced_accuracy", ascending=False)
    )

    runtime_summary = (
        runtime
        .groupby(["method_id", "dataset_id"], as_index=False)
        .agg(
            n_jobs=("total_seconds", "count"),
            mean_train_seconds=("train_seconds", "mean"),
            mean_predict_seconds=("predict_seconds", "mean"),
            mean_total_seconds=("total_seconds", "mean"),
            max_total_seconds=("total_seconds", "max"),
            sum_total_seconds=("total_seconds", "sum"),
        )
    )

    status_summary = (
        status
        .groupby(["status", "method_id"], as_index=False)
        .agg(
            n_jobs=("job_id", "count"),
            mean_total_seconds=("total_seconds", "mean"),
            max_total_seconds=("total_seconds", "max"),
        )
    )

    best = (
        dataset_method
        .sort_values(["dataset_id", "balanced_accuracy_mean"], ascending=[True, False])
        .groupby("dataset_id", as_index=False)
        .first()
    )

    dataset_method.to_csv(OUT / "pyrrm_cv10x10_dataset_method_summary.csv", index=False)
    overall.to_csv(OUT / "pyrrm_cv10x10_overall_summary.csv", index=False)
    runtime_summary.to_csv(OUT / "pyrrm_cv10x10_runtime_summary.csv", index=False)
    status_summary.to_csv(OUT / "pyrrm_cv10x10_status_summary.csv", index=False)
    best.to_csv(OUT / "pyrrm_cv10x10_best_method_by_dataset.csv", index=False)

    md = [
        "# pyrrm relational kNN cv10x10 benchmark summary",
        "",
        "This document summarizes the full pyrrm relational kNN benchmark.",
        "",
        "Method:",
        "",
        "- `pyrrm_knn5`",
        "- metric: `pyrrm.relative_relation_metric`",
        "- classifier: `sklearn.neighbors.KNeighborsClassifier`",
        "- k = 5",
        "- train-only MAD feature filtering",
        "- n_features = 50",
        "",
        "Protocol:",
        "",
        "- 8 datasets",
        "- 10 repeats",
        "- 10 folds per repeat",
        "- 800 total jobs",
        "- 800 completed jobs expected",
        "- 0 failed jobs expected",
        "",
        "## Overall summary",
        "",
        "| method_id | mean balanced accuracy | mean macro-F1 | mean MCC | mean n_features | k |",
        "|---|---:|---:|---:|---:|---:|",
    ]

    for _, r in overall.iterrows():
        md.append(
            f"| {r['method_id']} | {r['mean_balanced_accuracy']:.4f} | "
            f"{r['mean_macro_f1']:.4f} | {r['mean_mcc']:.4f} | "
            f"{r['mean_n_features']:.1f} | {r['mean_k']:.1f} |"
        )

    md.extend([
        "",
        "## Dataset-level summary",
        "",
        "| dataset_id | balanced accuracy | macro-F1 | MCC |",
        "|---|---:|---:|---:|",
    ])

    for _, r in dataset_method.iterrows():
        md.append(
            f"| {r['dataset_id']} | {r['balanced_accuracy_mean']:.4f} | "
            f"{r['macro_f1_mean']:.4f} | {r['mcc_mean']:.4f} |"
        )

    md.extend([
        "",
        "## Interpretation note",
        "",
        "`pyrrm_knn5` is included as the exact pyrrm relative-relation metric used inside a standard sklearn kNN classifier. It is therefore distinct from the ordinary Euclidean kNN baseline already included in the R benchmark.",
    ])

    (DOCS / "pyrrm_cv10x10_summary.md").write_text("\n".join(md), encoding="utf-8")

    print("\n=== pyrrm overall summary ===")
    print(overall)

    print("\nWritten:")
    print(OUT / "pyrrm_cv10x10_dataset_method_summary.csv")
    print(OUT / "pyrrm_cv10x10_overall_summary.csv")
    print(OUT / "pyrrm_cv10x10_runtime_summary.csv")
    print(OUT / "pyrrm_cv10x10_status_summary.csv")
    print(OUT / "pyrrm_cv10x10_best_method_by_dataset.csv")
    print(DOCS / "pyrrm_cv10x10_summary.md")


if __name__ == "__main__":
    main()
