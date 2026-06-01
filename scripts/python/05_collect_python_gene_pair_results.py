#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path
import pandas as pd
import numpy as np


ROOT = Path(".")
IN = ROOT / "results" / "python_jobs"
OUT = ROOT / "results" / "summary"
DOCS = ROOT / "docs"

OUT.mkdir(parents=True, exist_ok=True)
DOCS.mkdir(parents=True, exist_ok=True)


def read_many(path: Path, pattern: str) -> pd.DataFrame:
    files = sorted(path.glob(pattern))
    if not files:
        raise SystemExit(f"No files found: {path}/{pattern}")
    return pd.concat((pd.read_csv(f) for f in files), ignore_index=True)


def main() -> None:
    metrics = read_many(IN / "metrics", "*.csv")
    runtime = read_many(IN / "runtime", "*.csv")
    model_info = read_many(IN / "model_info", "*.csv")
    status_files = sorted((IN / "status").glob("*.done"))
    fail_files = sorted((IN / "status").glob("*.fail"))

    status = pd.concat((pd.read_csv(f) for f in status_files), ignore_index=True)

    print("Metric files:", len(list((IN / "metrics").glob("*.csv"))))
    print("Runtime files:", len(list((IN / "runtime").glob("*.csv"))))
    print("Model info files:", len(list((IN / "model_info").glob("*.csv"))))
    print("Done files:", len(status_files))
    print("Fail files:", len(fail_files))

    metric_cols = ["accuracy", "balanced_accuracy", "macro_f1", "mcc"]

    dataset_method = (
        metrics
        .groupby(["dataset_id", "method_id"], as_index=False)
        .agg({
            "accuracy": ["mean", "std"],
            "balanced_accuracy": ["mean", "std"],
            "macro_f1": ["mean", "std"],
            "mcc": ["mean", "std"],
            "n_pairs": "mean",
        })
    )

    dataset_method.columns = [
        "_".join(c).rstrip("_") if isinstance(c, tuple) else c
        for c in dataset_method.columns
    ]

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
            mean_n_pairs=("n_pairs_mean", "mean"),
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

    model_summary = (
        model_info
        .groupby(["method_id", "dataset_id"], as_index=False)
        .agg(
            n_jobs=("n_pairs", "count"),
            mean_n_features_used=("n_features_used", "mean"),
            mean_n_pairs=("n_pairs", "mean"),
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

    best_by_dataset = (
        dataset_method
        .sort_values(["dataset_id", "balanced_accuracy_mean"], ascending=[True, False])
        .groupby("dataset_id", as_index=False)
        .first()
    )

    paths = {
        "dataset_method": OUT / "python_gene_pair_cv10x10_dataset_method_summary.csv",
        "overall": OUT / "python_gene_pair_cv10x10_overall_summary.csv",
        "runtime": OUT / "python_gene_pair_cv10x10_runtime_summary.csv",
        "model": OUT / "python_gene_pair_cv10x10_model_info_summary.csv",
        "status": OUT / "python_gene_pair_cv10x10_status_summary.csv",
        "best": OUT / "python_gene_pair_cv10x10_best_method_by_dataset.csv",
    }

    dataset_method.to_csv(paths["dataset_method"], index=False)
    overall.to_csv(paths["overall"], index=False)
    runtime_summary.to_csv(paths["runtime"], index=False)
    model_summary.to_csv(paths["model"], index=False)
    status_summary.to_csv(paths["status"], index=False)
    best_by_dataset.to_csv(paths["best"], index=False)

    def fmt(x):
        if pd.isna(x):
            return ""
        if isinstance(x, (float, np.floating)):
            return f"{x:.4f}"
        return str(x)

    md = [
        "# Python gene-pair cv10x10 benchmark summary",
        "",
        "This document summarizes the full Python gene-pair benchmark.",
        "",
        "Implemented benchmark-style wrappers:",
        "",
        "- `py_tsp`",
        "- `py_tsp_svm`",
        "- `py_tsp_rf`",
        "- `py_reos`",
        "- `py_reos_svm`",
        "",
        "These methods are benchmark-compatible wrappers inspired by the external wucc009 notebook sections. They are not a verbatim notebook execution because the notebook depends on manual file paths, intermediate CSVs, and notebook state.",
        "",
        "Protocol:",
        "",
        "- 8 datasets",
        "- 10 repeats",
        "- 10 folds per repeat",
        "- 5 Python gene-pair methods",
        "- 4000 total jobs",
        "- 4000 completed jobs",
        "- 0 failed jobs",
        "",
        "## Overall summary",
        "",
        "| method_id | mean balanced accuracy | mean macro-F1 | mean MCC | mean n pairs |",
        "|---|---:|---:|---:|---:|",
    ]

    for _, r in overall.iterrows():
        md.append(
            f"| {r['method_id']} | {fmt(r['mean_balanced_accuracy'])} | "
            f"{fmt(r['mean_macro_f1'])} | {fmt(r['mean_mcc'])} | {fmt(r['mean_n_pairs'])} |"
        )

    md.extend([
        "",
        "## Best Python gene-pair method per dataset",
        "",
        "| dataset_id | method_id | balanced accuracy | macro-F1 | MCC |",
        "|---|---|---:|---:|---:|",
    ])

    for _, r in best_by_dataset.iterrows():
        md.append(
            f"| {r['dataset_id']} | {r['method_id']} | "
            f"{fmt(r['balanced_accuracy_mean'])} | {fmt(r['macro_f1_mean'])} | {fmt(r['mcc_mean'])} |"
        )

    md.extend([
        "",
        "## Interpretation note",
        "",
        "These Python methods expand Figure 4 / method-coverage support. They should be reported as additional benchmark-compatible gene-pair wrappers inspired by the external notebook, not as exact reproductions of the original notebook workflow.",
    ])

    doc_path = DOCS / "python_gene_pair_cv10x10_summary.md"
    doc_path.write_text("\n".join(md), encoding="utf-8")

    print("\n=== Python gene-pair overall summary ===")
    print(overall)

    print("\nWritten:")
    for p in paths.values():
        print(p)
    print(doc_path)


if __name__ == "__main__":
    main()
