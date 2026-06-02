#!/usr/bin/env python3
from pathlib import Path
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
SUMMARY = ROOT / "results" / "summary"
FIG = ROOT / "figures"
TABLES = ROOT / "results" / "tables"
FIG.mkdir(parents=True, exist_ok=True)
TABLES.mkdir(parents=True, exist_ok=True)

overall_path = SUMMARY / "harmonized_cv5x5_f200_complete_overall_summary.csv"
dataset_path = SUMMARY / "harmonized_cv5x5_f200_complete_dataset_method_summary.csv"
if not overall_path.exists():
    raise SystemExit(f"Missing {overall_path}")
if not dataset_path.exists():
    raise SystemExit(f"Missing {dataset_path}")

overall = pd.read_csv(overall_path)
dataset = pd.read_csv(dataset_path)

# Excel export is useful for reviewers, but should not make figure generation fail
# on minimal Python installations. CSV copies are always written.
overall.to_csv(TABLES / "final_overall_summary.csv", index=False)
dataset.to_csv(TABLES / "final_dataset_method_summary.csv", index=False)

try:
    import openpyxl  # noqa: F401
    overall.to_excel(TABLES / "final_overall_summary.xlsx", index=False)
    dataset.to_excel(TABLES / "final_dataset_method_summary.xlsx", index=False)
except Exception as exc:
    print(f"WARNING: Excel export skipped because openpyxl/xlsx support is unavailable: {exc}")

display = {
    "switchbox_tsp": ("TSP", "Compact relational rules"),
    "switchbox_ktsp": ("k-TSP", "Compact relational rules"),
    "tspdt_bigtsp": ("TSPDT", "Relational trees / rule sets"),
    "py_reos": ("REO-like", "Relational trees / rule sets"),
    "rrf_ranktreeensemble": ("RRF", "Rank / relational ensembles"),
    "pyrrm_knn5": ("RRM-kNN", "Relational metric / instance-based"),
    "py_tsp_rf": ("TSP+RF", "Relational representation + ML"),
    "py_tsp_svm": ("TSP+SVM", "Relational representation + ML"),
    "py_reos_svm": ("REO+SVM", "Relational representation + ML"),
    "glmnet_enet": ("glmnet", "Conventional ML references"),
    "svm_linear": ("linear SVM", "Conventional ML references"),
    "ranger_rf": ("RF", "Conventional ML references"),
    "xgboost_shallow": ("XGBoost", "Conventional ML references"),
    "knn_euclidean": ("kNN", "Conventional ML references"),
    "rpart_tree": ("CART", "Conventional ML references"),
}

group_order = [
    "Compact relational rules",
    "Relational trees / rule sets",
    "Rank / relational ensembles",
    "Relational metric / instance-based",
    "Relational representation + ML",
    "Conventional ML references",
]

fig_df = overall[overall["method_id"].isin(display)].copy()
fig_df["label"] = fig_df["method_id"].map(lambda x: display[x][0])
fig_df["group"] = fig_df["method_id"].map(lambda x: display[x][1])
fig_df["ba_pct"] = fig_df["mean_balanced_accuracy"] * 100.0
fig_df["group_order"] = fig_df["group"].map({g: i for i, g in enumerate(group_order)})
fig_df = fig_df.sort_values(["group_order", "ba_pct"], ascending=[True, False])

labels, ypos, xvals, groups = [], [], [], []
y = 0.0
for group in group_order:
    sub = fig_df[fig_df["group"] == group]
    if sub.empty:
        continue
    for _, r in sub.iterrows():
        labels.append(r["label"])
        xvals.append(r["ba_pct"])
        ypos.append(y)
        groups.append(group)
        y += 1.0
    y += 0.75

plt.figure(figsize=(10.5, 8.5))
plt.scatter(xvals, ypos, s=95, facecolors="white", edgecolors="black", linewidths=1.5)
for x, yy in zip(xvals, ypos):
    plt.plot([45, x], [yy, yy], linewidth=0.7)
plt.yticks(ypos, labels)
plt.xlabel("Mean balanced accuracy (%)", fontsize=13, fontweight="bold")
plt.ylabel("Method", fontsize=13, fontweight="bold")
plt.title("Benchmark comparison by method family", fontsize=14, fontweight="bold")
plt.xlim(45, max(xvals) + 2)
plt.grid(True, axis="x", linewidth=0.5)
for group in group_order:
    idx = [i for i, g in enumerate(groups) if g == group]
    if idx:
        ymid = sum(ypos[i] for i in idx) / len(idx)
        plt.text(45.2, ymid, group, va="center", ha="left", fontsize=9)
plt.tight_layout()
plt.savefig(FIG / "Fig4_method_family_balanced_accuracy.svg", format="svg")
plt.savefig(FIG / "Fig4_method_family_balanced_accuracy.png", dpi=250)
plt.close()

rank_df = overall.sort_values("mean_balanced_accuracy", ascending=True)
plt.figure(figsize=(10.5, 8.5))
plt.barh(rank_df["method_id"], rank_df["mean_balanced_accuracy"] * 100.0)
plt.xlabel("Mean balanced accuracy (%)", fontsize=13, fontweight="bold")
plt.ylabel("Method", fontsize=13, fontweight="bold")
plt.title("Overall benchmark ranking across 8 datasets", fontsize=14, fontweight="bold")
plt.grid(True, axis="x", linewidth=0.5)
plt.tight_layout()
plt.savefig(FIG / "Fig_overall_all_methods.svg", format="svg")
plt.savefig(FIG / "Fig_overall_all_methods.png", dpi=250)
plt.close()

heat = dataset.pivot(index="method_id", columns="dataset_id", values="balanced_accuracy_mean")
row_order = overall.sort_values("mean_balanced_accuracy", ascending=False)["method_id"].tolist()
heat = heat.reindex(row_order)
heat = heat[sorted(heat.columns)]
plt.figure(figsize=(12, 8.5))
img = plt.imshow(heat.values, aspect="auto")
plt.xticks(range(len(heat.columns)), heat.columns, rotation=45, ha="right")
plt.yticks(range(len(heat.index)), heat.index)
plt.xlabel("Dataset", fontsize=13, fontweight="bold")
plt.ylabel("Method", fontsize=13, fontweight="bold")
plt.title("Dataset-level mean balanced accuracy", fontsize=14, fontweight="bold")
plt.colorbar(img, label="Balanced accuracy")
plt.tight_layout()
plt.savefig(FIG / "Fig_dataset_level_heatmap.svg", format="svg")
plt.savefig(FIG / "Fig_dataset_level_heatmap.png", dpi=250)
plt.close()

(FIG / "FIGURE_NOTES.md").write_text(
    "# Figure notes\n\n"
    "`Fig4_method_family_balanced_accuracy` groups methods by model endpoint and representation family. "
    "The grouping is descriptive and is not intended as a calibrated interpretability score.\n\n"
    "TSPDT/BigTSP at f200 requires `Rscript --max-ppsize=500000`.\n",
    encoding="utf-8",
)

print("Written figures and tables under figures/ and results/tables/.")
