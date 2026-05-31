cat("=== AIR benchmark: make dataset-level result tables ===\n")

suppressPackageStartupMessages(library(data.table))

dir.create("results/summary", recursive = TRUE, showWarnings = FALSE)
dir.create("docs", recursive = TRUE, showWarnings = FALSE)

summary_path <- "results/summary/cv_10x10_dataset_method_summary.csv"

if (!file.exists(summary_path)) {
  stop("Missing file: ", summary_path)
}

x <- data.table::fread(summary_path, data.table = FALSE)

method_order <- c(
  "majority",
  "switchbox_tsp",
  "switchbox_ktsp",
  "tspdt_bigtsp",
  "rrf_ranktreeensemble",
  "glmnet_enet",
  "svm_linear",
  "knn_euclidean",
  "rpart_tree",
  "ranger_rf",
  "xgboost_shallow"
)

metric_cols <- c("accuracy", "balanced_accuracy", "macro_f1", "mcc")

x$method_id <- factor(x$method_id, levels = method_order)
x <- x[order(x$dataset_id, x$method_id), ]

make_wide <- function(metric) {
  wide <- reshape(
    x[, c("dataset_id", "method_id", metric)],
    idvar = "dataset_id",
    timevar = "method_id",
    direction = "wide"
  )

  colnames(wide) <- sub(paste0("^", metric, "\\."), "", colnames(wide))
  wide <- wide[, c("dataset_id", method_order[method_order %in% colnames(wide)]), drop = FALSE]

  wide
}

for (metric in metric_cols) {
  wide <- make_wide(metric)
  out <- file.path("results/summary", paste0("cv_10x10_", metric, "_by_dataset.csv"))
  data.table::fwrite(wide, out)
  cat("Written:", out, "\n")
}

# Best method per dataset by balanced accuracy.
best_balacc <- x[order(x$dataset_id, -x$balanced_accuracy), ]
best_balacc <- best_balacc[!duplicated(best_balacc$dataset_id), ]

best_out <- best_balacc[, c(
  "dataset_id",
  "method_id",
  "balanced_accuracy",
  "accuracy",
  "macro_f1",
  "mcc"
)]

data.table::fwrite(
  best_out,
  "results/summary/cv_10x10_best_method_by_dataset_balanced_accuracy.csv"
)

# Relational-only best per dataset.
rel_methods <- c(
  "switchbox_tsp",
  "switchbox_ktsp",
  "tspdt_bigtsp",
  "rrf_ranktreeensemble"
)

rel <- x[x$method_id %in% rel_methods, ]
best_rel <- rel[order(rel$dataset_id, -rel$balanced_accuracy), ]
best_rel <- best_rel[!duplicated(best_rel$dataset_id), ]

best_rel_out <- best_rel[, c(
  "dataset_id",
  "method_id",
  "balanced_accuracy",
  "accuracy",
  "macro_f1",
  "mcc"
)]

data.table::fwrite(
  best_rel_out,
  "results/summary/cv_10x10_best_relational_method_by_dataset_balanced_accuracy.csv"
)

# Method ranks per dataset by balanced accuracy.
ranked <- x[order(x$dataset_id, -x$balanced_accuracy), ]
ranked$rank_balanced_accuracy <- ave(
  -ranked$balanced_accuracy,
  ranked$dataset_id,
  FUN = function(z) rank(z, ties.method = "min")
)

ranked_out <- ranked[, c(
  "dataset_id",
  "method_id",
  "rank_balanced_accuracy",
  "balanced_accuracy",
  "accuracy",
  "macro_f1",
  "mcc"
)]

data.table::fwrite(
  ranked_out,
  "results/summary/cv_10x10_method_ranks_by_dataset.csv"
)

fmt <- function(z) {
  ifelse(is.na(z), "", sprintf("%.3f", z))
}

make_md_table <- function(df, cols) {
  header <- paste(cols, collapse = " | ")
  sep <- paste(rep("---", length(cols)), collapse = " | ")
  rows <- apply(df[, cols, drop = FALSE], 1, function(r) paste(r, collapse = " | "))
  paste(c(paste0("| ", header, " |"), paste0("| ", sep, " |"), paste0("| ", rows, " |")), collapse = "\n")
}

bal <- make_wide("balanced_accuracy")
for (cc in setdiff(colnames(bal), "dataset_id")) {
  bal[[cc]] <- fmt(bal[[cc]])
}

mf1 <- make_wide("macro_f1")
for (cc in setdiff(colnames(mf1), "dataset_id")) {
  mf1[[cc]] <- fmt(mf1[[cc]])
}

mcc <- make_wide("mcc")
for (cc in setdiff(colnames(mcc), "dataset_id")) {
  mcc[[cc]] <- fmt(mcc[[cc]])
}

best_out_md <- best_out
for (cc in c("balanced_accuracy", "accuracy", "macro_f1", "mcc")) {
  best_out_md[[cc]] <- fmt(best_out_md[[cc]])
}

best_rel_out_md <- best_rel_out
for (cc in c("balanced_accuracy", "accuracy", "macro_f1", "mcc")) {
  best_rel_out_md[[cc]] <- fmt(best_rel_out_md[[cc]])
}

md <- c(
  "# Dataset-level cv10x10 results",
  "",
  "This document reports dataset-level results for the full `cv_10x10` benchmark.",
  "",
  "Aggregation across all datasets is useful as a compact overview, but it hides strong dataset-specific behavior. Therefore, the tables below should be used when discussing method behavior in the manuscript or response to reviewers.",
  "",
  "## Balanced accuracy by dataset",
  "",
  make_md_table(bal, colnames(bal)),
  "",
  "## Macro-F1 by dataset",
  "",
  make_md_table(mf1, colnames(mf1)),
  "",
  "## MCC by dataset",
  "",
  make_md_table(mcc, colnames(mcc)),
  "",
  "## Best method per dataset by balanced accuracy",
  "",
  make_md_table(best_out_md, colnames(best_out_md)),
  "",
  "## Best relational method per dataset by balanced accuracy",
  "",
  make_md_table(best_rel_out_md, colnames(best_rel_out_md)),
  "",
  "## Interpretation note",
  "",
  "The classical baselines are lightweight, non-nested reference models. They should be described as reviewer-facing context rather than as fully optimized state-of-the-art baselines.",
  "",
  "The relational methods should be interpreted primarily as compact, transparent, within-sample relation-based classifiers. Their value is not only aggregate predictive performance, but also model simplicity and interpretability."
)

writeLines(md, "docs/dataset_level_results.md")

cat("Written: docs/dataset_level_results.md\n")
cat("=== Dataset-level tables finished ===\n")
