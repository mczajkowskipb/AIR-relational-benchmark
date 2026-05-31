cat("=== AIR benchmark: make classic ML job grid ===\n")

suppressPackageStartupMessages(library(data.table))

dir.create("results/job_grid", recursive = TRUE, showWarnings = FALSE)

protocol_id <- "cv_10x10"

fold_summary <- data.table::fread(
  file.path("data/manifests", paste0(protocol_id, "_fold_summary.csv")),
  data.table = FALSE
)

methods <- c(
  "glmnet_enet",
  "svm_linear",
  "knn_euclidean",
  "rpart_tree",
  "ranger_rf",
  "xgboost_shallow"
)

rows <- list()
k <- 0

for (dataset_id in fold_summary$dataset_id) {
  fold_path <- file.path("data/folds", paste0(protocol_id, "__", dataset_id, ".csv"))
  folds <- data.table::fread(fold_path, data.table = FALSE)
  combos <- unique(folds[, c("repeat_id", "fold_id")])

  for (method_id in methods) {
    for (i in seq_len(nrow(combos))) {
      k <- k + 1
      rows[[k]] <- data.frame(
        job_index = k,
        protocol_id = protocol_id,
        dataset_id = dataset_id,
        method_id = method_id,
        repeat_id = combos$repeat_id[i],
        fold_id = combos$fold_id[i],
        n_features = 200,
        stringsAsFactors = FALSE
      )
    }
  }
}

grid <- data.table::rbindlist(rows)

grid$command <- paste0(
  "Rscript scripts/10_run_single_job.R",
  " --protocol=", grid$protocol_id,
  " --dataset=", grid$dataset_id,
  " --method=", grid$method_id,
  " --repeat=", grid$repeat_id,
  " --fold=", grid$fold_id,
  " --n_features=", grid$n_features
)

out_csv <- "results/job_grid/cv_10x10_classic_job_grid.csv"
out_cmd <- "results/job_grid/cv_10x10_classic_commands.txt"

data.table::fwrite(grid, out_csv)
writeLines(grid$command, out_cmd)

cat("Jobs:", nrow(grid), "\n")
cat("Written:", out_csv, "\n")
cat("Written:", out_cmd, "\n")
cat("=== Classic job grid finished ===\n")
