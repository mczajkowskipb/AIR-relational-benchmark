cat("=== AIR benchmark: prepare final labeled datasets ===\n")

suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(jsonlite))

dir.create("data/final", recursive = TRUE, showWarnings = FALSE)
dir.create("data/manifests", recursive = TRUE, showWarnings = FALSE)

mapping <- data.table::fread("config/label_mapping.csv", data.table = FALSE)

split_values <- function(x) {
  if (is.na(x) || !nzchar(x)) return(character(0))
  trimws(unlist(strsplit(x, "\\|", fixed = FALSE)))
}

prepare_one <- function(row) {
  dataset_id <- row$dataset_id
  status <- row$status

  cat("\n=== Preparing:", dataset_id, "status:", status, "===\n")

  if (!identical(status, "APPROVED")) {
    msg <- paste0("Skipped because status is ", status)
    cat(msg, "\n")
    return(data.frame(
      dataset_id = dataset_id,
      status = "SKIPPED",
      n_samples = NA_integer_,
      n_features = NA_integer_,
      positive_label = NA_character_,
      negative_label = NA_character_,
      message = msg,
      stringsAsFactors = FALSE
    ))
  }

  processed_dir <- file.path("data/processed", dataset_id)
  final_dir <- file.path("data/final", dataset_id)
  dir.create(final_dir, recursive = TRUE, showWarnings = FALSE)

  expr_path <- file.path(processed_dir, "expression_matrix_features_x_samples.csv")
  if (!file.exists(expr_path)) {
    stop("Expression matrix not found: ", expr_path)
  }

  sample_metadata_path <- file.path(processed_dir, "sample_metadata.csv")
  gds_columns_path <- file.path(processed_dir, "gds_columns.csv")

  if (file.exists(sample_metadata_path)) {
    meta_path <- sample_metadata_path
  } else if (file.exists(gds_columns_path)) {
    meta_path <- gds_columns_path
  } else {
    stop("No metadata file found for ", dataset_id)
  }

  expr <- data.table::fread(expr_path, data.table = FALSE)
  meta <- data.table::fread(meta_path, data.table = FALSE)

  label_column <- row$label_column
  sample_id_column <- row$sample_id_column

  if (!label_column %in% colnames(meta)) {
    stop("Label column not found in metadata: ", label_column)
  }

  if (!sample_id_column %in% colnames(meta)) {
    stop("Sample ID column not found in metadata: ", sample_id_column)
  }

  positive_raw_values <- split_values(row$positive_raw)
  negative_raw_values <- split_values(row$negative_raw)
  exclude_raw_values <- split_values(row$exclude_raw_values)

  raw_label <- as.character(meta[[label_column]])
  sample_id <- as.character(meta[[sample_id_column]])

  keep_pos <- raw_label %in% positive_raw_values
  keep_neg <- raw_label %in% negative_raw_values
  keep_exclude <- raw_label %in% exclude_raw_values

  keep <- keep_pos | keep_neg
  keep[keep_exclude] <- FALSE

  final_raw_label <- raw_label[keep]
  final_sample_id <- sample_id[keep]

  class_label <- ifelse(
    final_raw_label %in% positive_raw_values,
    row$positive_label,
    ifelse(final_raw_label %in% negative_raw_values, row$negative_label, NA_character_)
  )

  y <- data.frame(
    dataset_id = dataset_id,
    sample_id = final_sample_id,
    raw_label = final_raw_label,
    class_label = class_label,
    positive_label = row$positive_label,
    negative_label = row$negative_label,
    stringsAsFactors = FALSE
  )

  if (any(is.na(y$class_label))) {
    stop("Some retained samples have unresolved class_label for ", dataset_id)
  }

  if (nrow(y) == 0) {
    stop("No samples retained for ", dataset_id)
  }

  if (length(unique(y$class_label)) != 2) {
    stop("Final labels are not binary for ", dataset_id)
  }

  if (!"feature_id" %in% colnames(expr)) {
    stop("Expression matrix must contain feature_id column: ", expr_path)
  }

  missing_samples <- setdiff(y$sample_id, colnames(expr))
  if (length(missing_samples) > 0) {
    stop(
      "Some labeled samples are missing from expression matrix for ",
      dataset_id,
      ": ",
      paste(head(missing_samples, 10), collapse = ", ")
    )
  }

  x <- expr[, c("feature_id", y$sample_id), drop = FALSE]

  x_path <- file.path(final_dir, "X_features_x_samples.csv")
  y_path <- file.path(final_dir, "y.csv")
  manifest_path <- file.path("data/manifests", paste0(dataset_id, "_final_manifest.json"))

  data.table::fwrite(x, x_path)
  data.table::fwrite(y, y_path)

  class_counts <- as.list(table(y$class_label))

  manifest <- list(
    dataset_id = dataset_id,
    label_column = label_column,
    sample_id_column = sample_id_column,
    positive_raw_values = positive_raw_values,
    negative_raw_values = negative_raw_values,
    positive_label = row$positive_label,
    negative_label = row$negative_label,
    exclude_raw_values = exclude_raw_values,
    n_samples = nrow(y),
    n_features = nrow(x),
    class_counts = class_counts,
    x_path = x_path,
    y_path = y_path,
    source_expression_path = expr_path,
    source_metadata_path = meta_path,
    notes = row$notes
  )

  jsonlite::write_json(manifest, manifest_path, pretty = TRUE, auto_unbox = TRUE)

  cat("Prepared final dataset:", dataset_id, "samples=", nrow(y), "features=", nrow(x), "\n")
  print(table(y$class_label))

  data.frame(
    dataset_id = dataset_id,
    status = "PREPARED",
    n_samples = nrow(y),
    n_features = nrow(x),
    positive_label = row$positive_label,
    negative_label = row$negative_label,
    message = "prepared",
    stringsAsFactors = FALSE
  )
}

res <- do.call(rbind, lapply(seq_len(nrow(mapping)), function(i) prepare_one(mapping[i, ])))

summary_path <- "data/manifests/final_dataset_summary.csv"
data.table::fwrite(res, summary_path)

cat("\n=== Final dataset preparation summary ===\n")
print(res)
cat("\nWritten:", summary_path, "\n")
cat("=== Final labeled dataset preparation finished ===\n")
