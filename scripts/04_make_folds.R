cat("=== AIR benchmark: make stratified CV folds ===\n")

suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(jsonlite))

dir.create("data/folds", recursive = TRUE, showWarnings = FALSE)
dir.create("data/manifests", recursive = TRUE, showWarnings = FALSE)

set.seed(20260530)

final_summary <- data.table::fread("data/manifests/final_dataset_summary.csv", data.table = FALSE)
final_summary <- final_summary[final_summary$status == "PREPARED", , drop = FALSE]

if (nrow(final_summary) == 0) {
  stop("No prepared final datasets found.")
}

make_stratified_folds <- function(y, n_folds, repeat_id, dataset_id) {
  y <- as.character(y$class_label)
  sample_id <- as.character(y_df$sample_id)

  fold_assignments <- rep(NA_integer_, length(y))

  for (cls in unique(y)) {
    idx <- which(y == cls)
    idx <- sample(idx)

    folds_for_class <- rep(seq_len(n_folds), length.out = length(idx))
    fold_assignments[idx] <- folds_for_class
  }

  rows <- lapply(seq_len(n_folds), function(fold_id) {
    test_idx <- which(fold_assignments == fold_id)
    train_idx <- setdiff(seq_along(y), test_idx)

    rbind(
      data.frame(
        dataset_id = dataset_id,
        repeat_id = repeat_id,
        fold_id = fold_id,
        sample_id = sample_id[train_idx],
        split = "train",
        class_label = y[train_idx],
        stringsAsFactors = FALSE
      ),
      data.frame(
        dataset_id = dataset_id,
        repeat_id = repeat_id,
        fold_id = fold_id,
        sample_id = sample_id[test_idx],
        split = "test",
        class_label = y[test_idx],
        stringsAsFactors = FALSE
      )
    )
  })

  do.call(rbind, rows)
}

make_protocol_folds <- function(protocol_id, repeats, folds) {
  cat("\n=== Protocol:", protocol_id, "repeats=", repeats, "folds=", folds, "===\n")

  protocol_rows <- list()
  summary_rows <- list()

  for (dataset_id in final_summary$dataset_id) {
    y_path <- file.path("data/final", dataset_id, "y.csv")
    if (!file.exists(y_path)) {
      stop("Missing y.csv for ", dataset_id, ": ", y_path)
    }

    y_df <<- data.table::fread(y_path, data.table = FALSE)

    class_counts <- table(y_df$class_label)
    min_class_n <- min(class_counts)

    if (min_class_n < folds) {
      stop(
        "Cannot create ", folds, "-fold CV for ", dataset_id,
        " because smallest class has only ", min_class_n, " samples."
      )
    }

    dataset_rows <- lapply(seq_len(repeats), function(r) {
      make_stratified_folds(
        y = y_df,
        n_folds = folds,
        repeat_id = r,
        dataset_id = dataset_id
      )
    })

    dataset_folds <- do.call(rbind, dataset_rows)

    out_path <- file.path("data/folds", paste0(protocol_id, "__", dataset_id, ".csv"))
    data.table::fwrite(dataset_folds, out_path)

    cat("Wrote:", out_path, "\n")

    protocol_rows[[dataset_id]] <- dataset_folds

    check <- as.data.frame(
      xtabs(~ repeat_id + fold_id + split + class_label, data = dataset_folds)
    )
    check <- check[check$Freq > 0, ]

    summary_path <- file.path("data/folds", paste0(protocol_id, "__", dataset_id, "__balance_check.csv"))
    data.table::fwrite(check, summary_path)

    summary_rows[[dataset_id]] <- data.frame(
      protocol_id = protocol_id,
      dataset_id = dataset_id,
      repeats = repeats,
      folds = folds,
      n_samples = nrow(y_df),
      class_counts = paste(names(class_counts), as.integer(class_counts), sep = "=", collapse = ";"),
      folds_path = out_path,
      balance_check_path = summary_path,
      stringsAsFactors = FALSE
    )
  }

  protocol_summary <- do.call(rbind, summary_rows)
  summary_out <- file.path("data/manifests", paste0(protocol_id, "_fold_summary.csv"))
  data.table::fwrite(protocol_summary, summary_out)

  manifest <- list(
    protocol_id = protocol_id,
    repeats = repeats,
    folds = folds,
    stratified = TRUE,
    seed = 20260530,
    datasets = final_summary$dataset_id,
    summary_path = summary_out
  )

  manifest_out <- file.path("data/manifests", paste0(protocol_id, "_fold_manifest.json"))
  jsonlite::write_json(manifest, manifest_out, pretty = TRUE, auto_unbox = TRUE)

  cat("Wrote:", summary_out, "\n")
  cat("Wrote:", manifest_out, "\n")

  invisible(protocol_summary)
}

smoke_summary <- make_protocol_folds(
  protocol_id = "smoke_2x2",
  repeats = 2,
  folds = 2
)

full_summary <- make_protocol_folds(
  protocol_id = "cv_10x10",
  repeats = 10,
  folds = 10
)

cat("\n=== Smoke fold summary ===\n")
print(smoke_summary)

cat("\n=== Full fold summary ===\n")
print(full_summary)

cat("=== Fold generation finished ===\n")
