cat("=== AIR benchmark: collect cv10x10 results ===\n")

suppressPackageStartupMessages(library(data.table))

dir.create("results/summary", recursive = TRUE, showWarnings = FALSE)

protocol_id <- "cv_10x10"

metric_files <- list.files("results/jobs/metrics", pattern = "\\.csv$", full.names = TRUE)
runtime_files <- list.files("results/jobs/runtime", pattern = "\\.csv$", full.names = TRUE)
model_info_files <- list.files("results/jobs/model_info", pattern = "\\.csv$", full.names = TRUE)
done_files <- list.files("results/jobs", pattern = "\\.done$", full.names = TRUE)
fail_files <- list.files("results/jobs", pattern = "\\.fail$", full.names = TRUE)

cat("Metric files:", length(metric_files), "\n")
cat("Runtime files:", length(runtime_files), "\n")
cat("Model info files:", length(model_info_files), "\n")
cat("Done files:", length(done_files), "\n")
cat("Fail files:", length(fail_files), "\n")

if (length(metric_files) == 0) stop("No metric files found.")
if (length(fail_files) > 0) warning("Fail files found: ", length(fail_files))

metrics <- data.table::rbindlist(lapply(metric_files, data.table::fread), fill = TRUE)
runtime <- data.table::rbindlist(lapply(runtime_files, data.table::fread), fill = TRUE)
model_info <- data.table::rbindlist(lapply(model_info_files, data.table::fread), fill = TRUE)
job_status <- data.table::rbindlist(lapply(done_files, data.table::fread), fill = TRUE)

metric_cols <- c(
  "accuracy",
  "balanced_accuracy",
  "macro_f1",
  "mcc",
  "sensitivity",
  "specificity",
  "f1_pos",
  "f1_neg",
  "auc",
  "brier",
  "logloss"
)

# Convert NaN to NA for clean summaries.
for (cc in intersect(metric_cols, colnames(metrics))) {
  set(metrics, i = which(is.nan(metrics[[cc]])), j = cc, value = NA_real_)
}

summary_mean <- metrics[
  ,
  lapply(.SD, function(z) mean(z, na.rm = TRUE)),
  by = .(dataset_id, method_id),
  .SDcols = intersect(metric_cols, colnames(metrics))
]

summary_sd <- metrics[
  ,
  lapply(.SD, function(z) stats::sd(z, na.rm = TRUE)),
  by = .(dataset_id, method_id),
  .SDcols = intersect(metric_cols, colnames(metrics))
]

setnames(
  summary_sd,
  old = intersect(metric_cols, colnames(summary_sd)),
  new = paste0(intersect(metric_cols, colnames(summary_sd)), "_sd")
)

summary_n <- metrics[
  ,
  .N,
  by = .(dataset_id, method_id)
]
setnames(summary_n, "N", "n_folds")

dataset_method_summary <- merge(summary_mean, summary_sd, by = c("dataset_id", "method_id"), all = TRUE)
dataset_method_summary <- merge(dataset_method_summary, summary_n, by = c("dataset_id", "method_id"), all = TRUE)

setorder(dataset_method_summary, dataset_id, method_id)

# Overall summary: average over dataset-level means, so each dataset has equal weight.
overall_summary <- dataset_method_summary[
  ,
  .(
    n_datasets = .N,
    mean_accuracy = mean(accuracy, na.rm = TRUE),
    mean_balanced_accuracy = mean(balanced_accuracy, na.rm = TRUE),
    mean_macro_f1 = mean(macro_f1, na.rm = TRUE),
    mean_mcc = mean(mcc, na.rm = TRUE),
    sd_balanced_accuracy_across_datasets = stats::sd(balanced_accuracy, na.rm = TRUE),
    sd_macro_f1_across_datasets = stats::sd(macro_f1, na.rm = TRUE),
    sd_mcc_across_datasets = stats::sd(mcc, na.rm = TRUE)
  ),
  by = method_id
]

setorder(overall_summary, -mean_balanced_accuracy)

runtime_summary <- runtime[
  ,
  .(
    n_jobs = .N,
    mean_train_seconds = mean(train_seconds, na.rm = TRUE),
    mean_predict_seconds = mean(predict_seconds, na.rm = TRUE),
    mean_total_seconds = mean(total_seconds, na.rm = TRUE),
    sum_total_seconds = sum(total_seconds, na.rm = TRUE)
  ),
  by = .(method_id, dataset_id)
]

setorder(runtime_summary, method_id, dataset_id)

model_info_summary <- model_info[
  ,
  .(
    n_jobs = .N,
    mean_model_size = mean(model_size, na.rm = TRUE),
    mean_n_features_used = mean(n_features_used, na.rm = TRUE),
    mean_n_relations_used = mean(n_relations_used, na.rm = TRUE)
  ),
  by = .(method_id, dataset_id)
]

setorder(model_info_summary, method_id, dataset_id)

job_status_summary <- job_status[
  ,
  .(
    n_jobs = .N,
    mean_total_seconds = mean(total_seconds, na.rm = TRUE),
    max_total_seconds = max(total_seconds, na.rm = TRUE)
  ),
  by = .(status, method_id)
]

out1 <- "results/summary/cv_10x10_dataset_method_summary.csv"
out2 <- "results/summary/cv_10x10_overall_method_summary.csv"
out3 <- "results/summary/cv_10x10_runtime_summary.csv"
out4 <- "results/summary/cv_10x10_model_info_summary.csv"
out5 <- "results/summary/cv_10x10_job_status_summary.csv"

data.table::fwrite(dataset_method_summary, out1)
data.table::fwrite(overall_summary, out2)
data.table::fwrite(runtime_summary, out3)
data.table::fwrite(model_info_summary, out4)
data.table::fwrite(job_status_summary, out5)

cat("\n=== Overall method summary ===\n")
print(overall_summary)

cat("\nWritten:\n")
cat(out1, "\n")
cat(out2, "\n")
cat(out3, "\n")
cat(out4, "\n")
cat(out5, "\n")

cat("=== cv10x10 collection finished ===\n")
