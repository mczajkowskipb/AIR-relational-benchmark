#!/usr/bin/env python3

from pathlib import Path
import pandas as pd

TSPDT_PROTOCOL = "cv_5x5_tspdt_f200_pps"
MAIN_PROTOCOL = "cv_5x5_f200"

OUT = Path("results/summary")
DOCS = Path("docs")
OUT.mkdir(parents=True, exist_ok=True)
DOCS.mkdir(parents=True, exist_ok=True)


def read_csvs(files):
    if not files:
        raise SystemExit("No CSV files found.")
    return pd.concat((pd.read_csv(f) for f in files), ignore_index=True)


def fmt(x):
    try:
        return f"{float(x):.4f}"
    except Exception:
        return ""


def main():
    metric_files = sorted(Path("results/jobs/metrics").glob(f"{TSPDT_PROTOCOL}__*__tspdt_bigtsp__*.csv"))
    done_files = sorted(Path("results/jobs").glob(f"{TSPDT_PROTOCOL}__*__tspdt_bigtsp__*.done"))
    fail_files = sorted(Path("results/jobs").glob(f"{TSPDT_PROTOCOL}__*__tspdt_bigtsp__*.fail"))

    tspdt_metrics = read_csvs(metric_files)
    tspdt_done = read_csvs(done_files) if done_files else pd.DataFrame()
    tspdt_fail = read_csvs(fail_files) if fail_files else pd.DataFrame()

    print("TSPDT f200 pps metric files:", len(metric_files))
    print("TSPDT f200 pps done files:", len(done_files))
    print("TSPDT f200 pps fail files:", len(fail_files))

    # Treat this as the successful f200 TSPDT result because folds and n_features match harmonized f200.
    tspdt_metrics["protocol_id"] = MAIN_PROTOCOL
    tspdt_metrics["method_id"] = "tspdt_bigtsp"
    tspdt_metrics["family"] = "R"

    tspdt_dataset = (
        tspdt_metrics
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

    tspdt_overall = (
        tspdt_dataset
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

    tspdt_status_frames = []
    if not tspdt_done.empty:
        tspdt_done["status_file_type"] = "done"
        tspdt_status_frames.append(tspdt_done)
    if not tspdt_fail.empty:
        tspdt_fail["status_file_type"] = "fail"
        tspdt_status_frames.append(tspdt_fail)

    tspdt_status = pd.concat(tspdt_status_frames, ignore_index=True) if tspdt_status_frames else pd.DataFrame()

    if not tspdt_status.empty:
        tspdt_status["method_id"] = "tspdt_bigtsp"
        tspdt_status_summary = (
            tspdt_status
            .groupby(["method_id", "status"], as_index=False)
            .agg(
                n_jobs=("job_id", "count"),
                mean_total_seconds=("total_seconds", "mean"),
                max_total_seconds=("total_seconds", "max"),
            )
        )
    else:
        tspdt_status_summary = pd.DataFrame()

    tspdt_dataset.to_csv(OUT / "tspdt_f200_pps_dataset_method_summary.csv", index=False)
    tspdt_overall.to_csv(OUT / "tspdt_f200_pps_overall_summary.csv", index=False)
    tspdt_status_summary.to_csv(OUT / "tspdt_f200_pps_status_summary.csv", index=False)

    base_dataset = pd.read_csv(OUT / "harmonized_cv5x5_f200_dataset_method_summary.csv")

    # harmonized_cv5x5_f200_dataset_method_summary excluded TSPDT, so we append successful TSPDT f200 pps.
    complete_dataset = pd.concat([base_dataset, tspdt_dataset], ignore_index=True)

    complete_overall = (
        complete_dataset
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

    ranked = complete_dataset.copy()
    ranked["rank_balanced_accuracy"] = (
        ranked.groupby("dataset_id")["balanced_accuracy_mean"].rank(method="min", ascending=False)
    )
    ranked = ranked.sort_values(["dataset_id", "rank_balanced_accuracy", "method_id"])

    best_all = ranked[ranked["rank_balanced_accuracy"] == 1].copy()

    classical_methods = {
        "majority",
        "glmnet_enet",
        "svm_linear",
        "knn_euclidean",
        "rpart_tree",
        "ranger_rf",
        "xgboost_shallow",
    }

    best_rel = (
        ranked[~ranked["method_id"].isin(classical_methods)]
        .sort_values(["dataset_id", "rank_balanced_accuracy"])
        .groupby("dataset_id", as_index=False)
        .first()
    )

    complete_dataset.to_csv(OUT / "harmonized_cv5x5_f200_complete_dataset_method_summary.csv", index=False)
    complete_overall.to_csv(OUT / "harmonized_cv5x5_f200_complete_overall_summary.csv", index=False)
    ranked.to_csv(OUT / "harmonized_cv5x5_f200_complete_method_ranks_by_dataset.csv", index=False)
    best_all.to_csv(OUT / "harmonized_cv5x5_f200_complete_best_method_by_dataset.csv", index=False)
    best_rel.to_csv(OUT / "harmonized_cv5x5_f200_complete_best_relational_method_by_dataset.csv", index=False)

    md = [
        "# Complete harmonized cv5x5 f200 benchmark summary",
        "",
        "This summary combines the harmonized `cv_5x5_f200` benchmark with the successful TSPDT f200 rerun.",
        "",
        "Protocol:",
        "",
        "- 8 datasets",
        "- 5 repeats",
        "- 5 folds per repeat",
        "- train-only MAD filtering to 200 features for all methods",
        "- balanced accuracy as the primary metric",
        "",
        "Technical note:",
        "",
        "- BigTSP/TSPDT initially failed at f200 with `protect(): protection stack overflow`.",
        "- The f200 TSPDT rerun succeeded after increasing R's protection stack using `Rscript --max-ppsize=500000`.",
        "- Therefore, the completed comparison includes TSPDT at f200, not f100 fallback.",
        "",
        "Completed jobs represented in this complete summary:",
        "",
        "- R methods including TSPDT: 2200 jobs",
        "- Python gene-pair wrappers: 1000 jobs",
        "- pyrrm relational kNN: 200 jobs",
        "- total completed jobs: 3400",
        "- total failed jobs in the final completed set: 0",
        "",
        "## Overall ranking by mean balanced accuracy",
        "",
        "| rank | method_id | family | mean balanced accuracy | mean macro-F1 | mean MCC |",
        "|---:|---|---|---:|---:|---:|",
    ]

    for i, (_, r) in enumerate(complete_overall.iterrows(), start=1):
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
        "This is the cleaner benchmark table for updated Figure 4-style visualization because all methods use the same 200-feature train-only MAD universe. TSPDT required the R protection-stack setting but otherwise used the same f200 feature universe and same 5×5 folds.",
    ])

    (DOCS / "harmonized_cv5x5_f200_complete_summary.md").write_text("\n".join(md), encoding="utf-8")

    print("\n=== TSPDT f200 pps overall ===")
    print(tspdt_overall)

    print("\n=== Complete merged overall ===")
    print(complete_overall)

    print("\nWritten complete harmonized files.")


if __name__ == "__main__":
    main()
