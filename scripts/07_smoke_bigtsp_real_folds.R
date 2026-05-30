cat("=== AIR benchmark: BigTSP tsp.tree smoke test on real folds ===\n")

suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(BigTSP))
suppressPackageStartupMessages(library(tree))

source("R/core/data_io.R")
source("R/core/preprocessing.R")
source("R/core/metrics.R")
source("R/core/model_interface.R")
source("R/methods/method_bigtsp.R")

dir.create("results/predictions", recursive = TRUE, showWarnings = FALSE)
dir.create("results/metrics", recursive = TRUE, showWarnings = FALSE)
dir.create("results/model_artifacts", recursive = TRUE, showWarnings = FALSE)
dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)
dir.create("results/selected_features", recursive = TRUE, showWarnings = FALSE)

protocol_id <- "smoke_2x2"
method_id <- "tspdt_bigtsp"

fold_summary <- data.table::fread(
  file.path("data/manifests", paste0(protocol_id, "_fold_summary.csv")),
  data.table = FALSE
)

all_metrics <- list()
all_runtime <- list()
all_model_info <- list()

job_counter <- 0

for (dataset_id in fold_summary$dataset_id) {
  cat("\n=== Dataset:", dataset_id, "===\n")

  ds <- load_final_dataset(dataset_id)
  folds <- load_fold_table(protocol_id, dataset_id)

  repeat_ids <- sort(unique(folds$repeat_id))
  fold_ids <- sort(unique(folds$fold_id))

  for (repeat_id in repeat_ids) {
    for (fold_id in fold_ids) {
      job_counter <- job_counter + 1

      cat("Running", method_id, dataset_id, "repeat", repeat_id, "fold", fold_id, "\n")

      split <- get_fold_split(ds, folds, repeat_id, fold_id)

      prep <- fit_preprocessing(
        split$x_train,
        feature_filter = "mad",
        n_features = min(100, ncol(split$x_train)),
        impute = TRUE,
        scale = FALSE
      )

      x_train_p <- apply_preprocessing(split$x_train, prep)
      x_test_p <- apply_preprocessing(split$x_test, prep)

      positive <- levels(split$y_train)[2]

      res <- fit_predict_bigtsp_tspdt(
        x_train = x_train_p,
        y_train = split$y_train,
        x_test = x_test_p,
        y_test = split$y_test,
        config = list(
          method_id = method_id,
          positive = positive,
          mincut = 2,
          minsize = 5,
          mindev = 0.001
        )
      )

      res$predictions$dataset_id <- dataset_id
      res$predictions$protocol_id <- protocol_id
      res$predictions$method_id <- method_id
      res$predictions$repeat_id <- repeat_id
      res$predictions$fold_id <- fold_id

      res$metrics$dataset_id <- dataset_id
      res$metrics$protocol_id <- protocol_id
      res$metrics$method_id <- method_id
      res$metrics$repeat_id <- repeat_id
      res$metrics$fold_id <- fold_id

      res$model_info$dataset_id <- dataset_id
      res$model_info$protocol_id <- protocol_id
      res$model_info$repeat_id <- repeat_id
      res$model_info$fold_id <- fold_id

      res$runtime$dataset_id <- dataset_id
      res$runtime$protocol_id <- protocol_id
      res$runtime$repeat_id <- repeat_id
      res$runtime$fold_id <- fold_id

      selected_table <- prep$selected_table
      selected_table$dataset_id <- dataset_id
      selected_table$protocol_id <- protocol_id
      selected_table$method_id <- method_id
      selected_table$repeat_id <- repeat_id
      selected_table$fold_id <- fold_id

      pred_path <- file.path(
        "results/predictions",
        paste0(protocol_id, "__", dataset_id, "__", method_id, "__r", repeat_id, "__f", fold_id, ".csv")
      )

      selected_path <- file.path(
        "results/selected_features",
        paste0(protocol_id, "__", dataset_id, "__", method_id, "__r", repeat_id, "__f", fold_id, ".csv")
      )

      model_path <- file.path(
        "results/model_artifacts",
        paste0(protocol_id, "__", dataset_id, "__", method_id, "__r", repeat_id, "__f", fold_id, ".rds")
      )

      data.table::fwrite(res$predictions, pred_path)
      data.table::fwrite(selected_table, selected_path)
      saveRDS(res$model, model_path)

      all_metrics[[job_counter]] <- res$metrics
      all_runtime[[job_counter]] <- res$runtime
      all_model_info[[job_counter]] <- res$model_info
    }
  }
}

metrics <- data.table::rbindlist(all_metrics, fill = TRUE)
runtime <- data.table::rbindlist(all_runtime, fill = TRUE)
model_info <- data.table::rbindlist(all_model_info, fill = TRUE)

metrics_path <- file.path("results/metrics", paste0(protocol_id, "__", method_id, "__metrics.csv"))
runtime_path <- file.path("results/runtime", paste0(protocol_id, "__", method_id, "__runtime.csv"))
model_info_path <- file.path("results/model_artifacts", paste0(protocol_id, "__", method_id, "__model_info.csv"))

data.table::fwrite(metrics, metrics_path)
data.table::fwrite(runtime, runtime_path)
data.table::fwrite(model_info, model_info_path)

metric_cols <- c("accuracy", "balanced_accuracy", "macro_f1", "mcc", "auc", "brier", "logloss")
metrics_df <- as.data.frame(metrics)

summary_agg <- aggregate(
  metrics_df[, metric_cols, drop = FALSE],
  by = list(dataset_id = metrics_df$dataset_id),
  FUN = function(z) mean(z, na.rm = TRUE)
)

summary_path <- file.path("results/metrics", paste0(protocol_id, "__", method_id, "__summary.csv"))
data.table::fwrite(summary_agg, summary_path)

cat("\n=== BigTSP tsp.tree smoke summary ===\n")
print(summary_agg)

cat("\nWritten:\n")
cat(metrics_path, "\n")
cat(runtime_path, "\n")
cat(model_info_path, "\n")
cat(summary_path, "\n")

cat("=== BigTSP tsp.tree smoke test finished ===\n")
