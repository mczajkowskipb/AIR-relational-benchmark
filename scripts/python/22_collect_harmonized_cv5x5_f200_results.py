#!/usr/bin/env python3

from pathlib import Path
import pandas as pd

PROTOCOL = "cv_5x5_f200"

OUT = Path("results/summary")
DOCS = Path("docs")
OUT.mkdir(parents=True, exist_ok=True)
DOCS.mkdir(parents=True, exist_ok=True)


def read_csvs(files):
    if not files:
        return pd.DataFrame()
    return pd.concat((pd.read_csv(f) for f in files), ignore_index=True)


def read_metric_family(base_dir, family):
    files = sorted(Path(base_dir).glob(f"{PROTOCOL}__*.csv"))
    x = read_csvs(files)
    if x.empty:
        return x

    x["family"] = family

    keep = [
        "dataset_id",
        "protocol_id",
        "method_id",
        "repeat_id",
        "fold_id",
        "family",
        "accuracy",
        "balanced_accuracy",
        "macro_f1",
        "mcc",
    ]

    for c in keep:
        if c not in x.columns:
            x[c] = None

    return x[keep]


def read_status_family(base_dir, family):
    base = Path(base_dir)
    done_files = sorted(base.glob(f"{PROTOCOL}__*.done"))
    fail_files = sorted(base.glob(f"{PROTOCOL}__*.fail"))

    frames = []

    if done_files:
        d = read_csvs(done_files)
        d["status_file_type"] = "done"
        frames.append(d)

    if fail_files:
        f = read_csvs(fail_files)
        f["status_file_type"] = "fail"
        frames.append(f)

    if not frames:
        return pd.DataFrame()

    x = pd.concat(frames, ignore_index=True)
    x["family"] = family
    return x


def main():
    r_metrics = read_metric_family("results/jobs/metrics", "R")
    py_metrics = read_metric_family("results/python_jobs/metrics", "python_gene_pair")
    pyrrm_metrics = read_metric_family("results/pyrrm_jobs/metrics", "pyrrm")

    all_metrics = pd.concat([r_metrics, py_metrics, pyrrm_metrics], ignore_index=True)

    # Exclude technical-fail TSPDT from the valid harmonized comparison.
    valid_metrics = all_metrics[all_metrics["method_id"] != "tspdt_bigtsp"].copy()

    r_status = read_status_family("results/jobs", "R")
    py_status = read_status_family("results/python_jobs/status", "python_gene_pair")
    pyrrm_status = read_status_family("results/pyrrm_jobs/status", "pyrrm")
    all_status = pd.concat([r_status, py_status, pyrrm_status], ignore_index=True)

    print("Metric rows total:", len(all_metrics))
    print("Metric rows valid excluding TSPDT:", len(valid_metrics))
    print("Status rows:", len(all_status))

    status_summary = (
        all_status
        .groupby(["family", "method_id", "status"], as_index=False)
        .agg(
            n_jobs=("job_id", "count"),
            mean_total_seconds=("total_seconds", "mean"),
            max_total_seconds=("total_seconds", "max"),
        )
        .sort_values(["family", "method_id", "status"])
    )

    dataset_method = (
        valid_metrics
        .groupby(["dataset_id", "method_id", "family"], as_index=False)
        .agg(
            n_jobs=("balanced_accuracy", "count"),
            accuracy_mean=("accuracy", "mean"),
            accuracy_std=("accuracy", "std"),
            balanced_accuracy_mean=("balanced_accuracy", "mean"),
            balanced_accuracy_std=("balanced_accuracy", "std"),
            macro_f1_mean=("macro_f1", "mean"),
            macro_f1_std=("macro_f1", "std"),
            mcc_mean=("mcc", "mean"),
            mcc_std=("mcc", "std"),
        )
        .sort_values(["dataset_id", "balanced_accuracy_mean"], ascending=[True, False])
    )

    overall = (
        dataset_method
        .groupby(["method_id", "family"], as_index=False)
        .agg(
            n_datasets=("dataset_id", "count"),
            mean_accuracy=("accuracy_mean", "mean"),
            mean_balanced_accuracy=("balanced_accuracy_mean", "mean"),
            mean_macro_f1=("macro_f1_mean", "mean"),
            mean_mcc=("mcc_mean", "mean"),
            sd_balanced_accuracy_across_datasets=("balanced_accuracy_mean", "std"),
            sd_macro_f1_across_datasets=("macro_f1_mean", "std"),
            sd_mcc_across_datasets=("mcc_mean", "std"),
        )
        .sort_values("mean_balanced_accuracy", ascending=False)
    )

    ranked = dataset_method.copy()
    ranked["rank_balanced_accuracy"] = (
        ranked
        .groupby("dataset_id")["balanced_accuracy_mean"]
        .rank(method="min", ascending=False)
    )
    ranked = ranked.sort_values(["dataset_id", "rank_balanced_accuracy", "method_id"])

    best_all = ranked[ranked["rank_balanced_accuracy"] == 1].copy()

    relational_groups = {"R", "python_gene_pair", "pyrrm"}
    classical_methods = {
        "majority",
        "glmnet_enet",
        "svm_linear",
        "knn_euclidean",
        "rpart_tree",
        "ranger_rf",
        "xgboost_shallow",
    }

    rel_ranked = ranked[~ranked["method_id"].isin(classical_methods)].copy()
    best_rel = (
        rel_ranked
        .sort_values(["dataset_id", "rank_balanced_accuracy"])
        .groupby("dataset_id", as_index=False)
        .first()
    )

    all_metrics.to_csv(OUT / "harmonized_cv5x5_f200_all_metric_rows_including_tspdt.csv", index=False)
    valid_metrics.to_csv(OUT / "harmonized_cv5x5_f200_valid_metric_rows.csv", index=False)
    status_summary.to_csv(OUT / "harmonized_cv5x5_f200_status_summary.csv", index=False)
    dataset_method.to_csv(OUT / "harmonized_cv5x5_f200_dataset_method_summary.csv", index=False)
    overall.to_csv(OUT / "harmonized_cv5x5_f200_overall_summary.csv", index=False)
    ranked.to_csv(OUT / "harmonized_cv5x5_f200_method_ranks_by_dataset.csv", index=False)
    best_all.to_csv(OUT / "harmonized_cv5x5_f200_best_method_by_dataset.csv", index=False)
    best_rel.to_csv(OUT / "harmonized_cv5x5_f200_best_relational_method_by_dataset.csv", index=False)

    def fmt(x):
        try:
            return f"{float(x):.4f}"
        except Exception:
            return ""

    md = [
        "# Harmonized cv5x5 f200 benchmark summary",
        "",
        "This benchmark uses a harmonized feature-universe setting:",
        "",
        "- 8 datasets",
        "- 5 repeats",
        "- 5 folds per repeat",
        "- train-only MAD filtering to 200 features for all methods",
        "- balanced accuracy as the primary metric",
        "",
        "Completed valid jobs:",
        "",
        "- R methods excluding BigTSP/TSPDT: 2000 jobs",
        "- Python gene-pair wrappers: 1000 jobs",
        "- pyrrm relational kNN: 200 jobs",
        "- valid completed jobs: 3200",
        "",
        "Technical failure:",
        "",
        "- `tspdt_bigtsp`: 200/200 failed at f200 due to `protect(): protection stack overflow`; excluded from the valid f200 comparison.",
        "",
        "## Overall ranking by mean balanced accuracy",
        "",
        "| rank | method_id | family | mean balanced accuracy | mean macro-F1 | mean MCC |",
        "|---:|---|---|---:|---:|---:|",
    ]

    for i, (_, r) in enumerate(overall.iterrows(), start=1):
        md.append(
            f"| {i} | {r['method_id']} | {r['family']} | "
            f"{fmt(r['mean_balanced_accuracy'])} | {fmt(r['mean_macro_f1'])} | {fmt(r['mean_mcc'])} |"
        )

    md.extend([
        "",
        "## Best method per dataset",
        "",
        "| dataset_id | method_id | family | balanced accuracy | macro-F1 | MCC |",
        "|---|---|---|---:|---:|---:|",
    ])

    for _, r in best_all.iterrows():
        md.append(
            f"| {r['dataset_id']} | {r['method_id']} | {r['family']} | "
            f"{fmt(r['balanced_accuracy_mean'])} | {fmt(r['macro_f1_mean'])} | {fmt(r['mcc_mean'])} |"
        )

    md.extend([
        "",
        "## Best relational / rank-based method per dataset",
        "",
        "| dataset_id | method_id | family | balanced accuracy | macro-F1 | MCC |",
        "|---|---|---|---:|---:|---:|",
    ])

    for _, r in best_rel.iterrows():
        md.append(
            f"| {r['dataset_id']} | {r['method_id']} | {r['family']} | "
            f"{fmt(r['balanced_accuracy_mean'])} | {fmt(r['macro_f1_mean'])} | {fmt(r['mcc_mean'])} |"
        )

    md.extend([
        "",
        "## Interpretation note",
        "",
        "This harmonized benchmark is intended as the cleaner comparison for updated Figure 4-style visualization because all included valid methods use the same 200-feature train-only MAD universe. The previous cv10x10 benchmark remains useful as a broader repository validation run.",
    ])

    (DOCS / "harmonized_cv5x5_f200_summary.md").write_text("\n".join(md), encoding="utf-8")

    print("\n=== Harmonized overall ===")
    print(overall)

    print("\nWritten harmonized summary files.")


if __name__ == "__main__":
    main()
