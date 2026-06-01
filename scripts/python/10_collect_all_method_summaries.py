#!/usr/bin/env python3

from pathlib import Path
import pandas as pd

OUT = Path("results/summary")
DOCS = Path("docs")
OUT.mkdir(parents=True, exist_ok=True)
DOCS.mkdir(parents=True, exist_ok=True)


def load_r_summary():
    path = OUT / "cv_10x10_dataset_method_summary.csv"
    x = pd.read_csv(path)

    rows = []
    for _, r in x.iterrows():
        rows.append({
            "dataset_id": r["dataset_id"],
            "method_id": r["method_id"],
            "source_group": classify_method(r["method_id"]),
            "accuracy": r.get("accuracy", None),
            "balanced_accuracy": r.get("balanced_accuracy", None),
            "macro_f1": r.get("macro_f1", None),
            "mcc": r.get("mcc", None),
        })
    return pd.DataFrame(rows)


def load_python_gene_pair_summary():
    path = OUT / "python_gene_pair_cv10x10_dataset_method_summary.csv"
    x = pd.read_csv(path)

    rows = []
    for _, r in x.iterrows():
        rows.append({
            "dataset_id": r["dataset_id"],
            "method_id": r["method_id"],
            "source_group": "python_gene_pair",
            "accuracy": r.get("accuracy_mean", None),
            "balanced_accuracy": r.get("balanced_accuracy_mean", None),
            "macro_f1": r.get("macro_f1_mean", None),
            "mcc": r.get("mcc_mean", None),
        })
    return pd.DataFrame(rows)


def load_pyrrm_summary():
    path = OUT / "pyrrm_cv10x10_dataset_method_summary.csv"
    x = pd.read_csv(path)

    rows = []
    for _, r in x.iterrows():
        rows.append({
            "dataset_id": r["dataset_id"],
            "method_id": r["method_id"],
            "source_group": "pyrrm_relational_knn",
            "accuracy": r.get("accuracy_mean", None),
            "balanced_accuracy": r.get("balanced_accuracy_mean", None),
            "macro_f1": r.get("macro_f1_mean", None),
            "mcc": r.get("mcc_mean", None),
        })
    return pd.DataFrame(rows)


def classify_method(method_id: str) -> str:
    relational_r = {
        "switchbox_tsp",
        "switchbox_ktsp",
        "tspdt_bigtsp",
        "rrf_ranktreeensemble",
    }

    classical_r = {
        "majority",
        "glmnet_enet",
        "svm_linear",
        "knn_euclidean",
        "rpart_tree",
        "ranger_rf",
        "xgboost_shallow",
    }

    if method_id in relational_r:
        return "r_relational"
    if method_id in classical_r:
        return "r_classical_reference"
    return "other"


def fmt(z):
    try:
        return f"{float(z):.4f}"
    except Exception:
        return ""


def main():
    frames = [
        load_r_summary(),
        load_python_gene_pair_summary(),
        load_pyrrm_summary(),
    ]

    all_dataset = pd.concat(frames, ignore_index=True)
    all_dataset = all_dataset.sort_values(["dataset_id", "source_group", "method_id"])

    overall = (
        all_dataset
        .groupby(["method_id", "source_group"], as_index=False)
        .agg(
            n_datasets=("dataset_id", "count"),
            mean_accuracy=("accuracy", "mean"),
            mean_balanced_accuracy=("balanced_accuracy", "mean"),
            mean_macro_f1=("macro_f1", "mean"),
            mean_mcc=("mcc", "mean"),
            sd_balanced_accuracy_across_datasets=("balanced_accuracy", "std"),
            sd_macro_f1_across_datasets=("macro_f1", "std"),
            sd_mcc_across_datasets=("mcc", "std"),
        )
        .sort_values("mean_balanced_accuracy", ascending=False)
    )

    ranked = all_dataset.copy()
    ranked["rank_balanced_accuracy"] = (
        ranked
        .groupby("dataset_id")["balanced_accuracy"]
        .rank(method="min", ascending=False)
    )
    ranked = ranked.sort_values(["dataset_id", "rank_balanced_accuracy", "method_id"])

    best_all = ranked[ranked["rank_balanced_accuracy"] == 1].copy()

    # best relational-like only
    rel_groups = {"r_relational", "python_gene_pair", "pyrrm_relational_knn"}
    rel = ranked[ranked["source_group"].isin(rel_groups)].copy()
    best_rel = (
        rel
        .sort_values(["dataset_id", "rank_balanced_accuracy"])
        .groupby("dataset_id", as_index=False)
        .first()
    )

    all_dataset.to_csv(OUT / "all_methods_cv10x10_dataset_method_summary.csv", index=False)
    overall.to_csv(OUT / "all_methods_cv10x10_overall_summary.csv", index=False)
    ranked.to_csv(OUT / "all_methods_cv10x10_method_ranks_by_dataset.csv", index=False)
    best_all.to_csv(OUT / "all_methods_cv10x10_best_method_by_dataset.csv", index=False)
    best_rel.to_csv(OUT / "all_methods_cv10x10_best_relational_method_by_dataset.csv", index=False)

    md = [
        "# Combined cv10x10 benchmark summary",
        "",
        "This document combines all currently completed benchmark families:",
        "",
        "- R relational methods",
        "- R lightweight classical reference baselines",
        "- Python gene-pair wrappers inspired by the wucc009 notebook",
        "- pyrrm relational kNN",
        "",
        "Completed jobs represented in the repository summaries:",
        "",
        "- R benchmark: 8800 jobs",
        "- Python gene-pair benchmark: 4000 jobs",
        "- pyrrm benchmark: 800 jobs",
        "- Total summarized jobs: 13600 jobs",
        "",
        "## Overall ranking by mean balanced accuracy",
        "",
        "| rank | method_id | group | mean balanced accuracy | mean macro-F1 | mean MCC |",
        "|---:|---|---|---:|---:|---:|",
    ]

    for i, (_, r) in enumerate(overall.iterrows(), start=1):
        md.append(
            f"| {i} | {r['method_id']} | {r['source_group']} | "
            f"{fmt(r['mean_balanced_accuracy'])} | {fmt(r['mean_macro_f1'])} | {fmt(r['mean_mcc'])} |"
        )

    md.extend([
        "",
        "## Best method per dataset",
        "",
        "| dataset_id | method_id | group | balanced accuracy | macro-F1 | MCC |",
        "|---|---|---|---:|---:|---:|",
    ])

    for _, r in best_all.iterrows():
        md.append(
            f"| {r['dataset_id']} | {r['method_id']} | {r['source_group']} | "
            f"{fmt(r['balanced_accuracy'])} | {fmt(r['macro_f1'])} | {fmt(r['mcc'])} |"
        )

    md.extend([
        "",
        "## Best relational / gene-pair / pyrrm method per dataset",
        "",
        "| dataset_id | method_id | group | balanced accuracy | macro-F1 | MCC |",
        "|---|---|---|---:|---:|---:|",
    ])

    for _, r in best_rel.iterrows():
        md.append(
            f"| {r['dataset_id']} | {r['method_id']} | {r['source_group']} | "
            f"{fmt(r['balanced_accuracy'])} | {fmt(r['macro_f1'])} | {fmt(r['mcc'])} |"
        )

    md.extend([
        "",
        "## Interpretation note",
        "",
        "The combined table should not be read as a claim that all methods are directly equivalent implementations from the original publications. The R methods and classical baselines are benchmark wrappers in the AIR repository. The Python gene-pair methods are benchmark-compatible wrappers inspired by the external notebook. The pyrrm result uses the exact pyrrm relative-relation metric inside sklearn kNN.",
        "",
        "Dataset-level tables are more informative than the global mean because the behavior is strongly dataset-dependent.",
    ])

    (DOCS / "combined_cv10x10_benchmark_summary.md").write_text("\n".join(md), encoding="utf-8")

    print("Written:")
    print(OUT / "all_methods_cv10x10_dataset_method_summary.csv")
    print(OUT / "all_methods_cv10x10_overall_summary.csv")
    print(OUT / "all_methods_cv10x10_method_ranks_by_dataset.csv")
    print(OUT / "all_methods_cv10x10_best_method_by_dataset.csv")
    print(OUT / "all_methods_cv10x10_best_relational_method_by_dataset.csv")
    print(DOCS / "combined_cv10x10_benchmark_summary.md")

    print("\n=== Overall ===")
    print(overall)


if __name__ == "__main__":
    main()
