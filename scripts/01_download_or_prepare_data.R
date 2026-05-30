cat("=== AIR benchmark: download / prepare GEO datasets ===\n")

suppressPackageStartupMessages(library(GEOquery))
suppressPackageStartupMessages(library(Biobase))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(jsonlite))

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("data/manifests", recursive = TRUE, showWarnings = FALSE)
dir.create("results/logs", recursive = TRUE, showWarnings = FALSE)

datasets <- read.csv("config/datasets.csv", stringsAsFactors = FALSE)

safe_write_csv <- function(x, path) {
  data.table::fwrite(as.data.frame(x), path)
}

find_candidate_label_columns <- function(pheno) {
  if (is.null(pheno) || ncol(pheno) == 0) {
    return(character(0))
  }

  patterns <- c(
    "title",
    "source",
    "character",
    "disease",
    "diagnosis",
    "status",
    "group",
    "class",
    "phenotype",
    "tissue",
    "description",
    "cell",
    "condition",
    "case",
    "control"
  )

  cols <- colnames(pheno)
  hit <- unique(unlist(lapply(patterns, function(p) {
    grep(p, cols, ignore.case = TRUE, value = TRUE)
  })))

  hit
}

prepare_gse <- function(dataset_id) {
  cat("\n=== Processing GSE:", dataset_id, "===\n")

  out_dir <- file.path("data/processed", dataset_id)
  raw_dir <- file.path("data/raw", dataset_id)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

  rds_path <- file.path(raw_dir, paste0(dataset_id, "_GEOquery_raw.rds"))

  if (file.exists(rds_path)) {
    cat("Raw RDS exists, loading:", rds_path, "\n")
    gse <- readRDS(rds_path)
  } else {
    gse <- GEOquery::getGEO(
      dataset_id,
      GSEMatrix = TRUE,
      AnnotGPL = FALSE,
      getGPL = FALSE,
      destdir = raw_dir
    )
    saveRDS(gse, rds_path)
  }

  if (!is.list(gse)) {
    gse <- list(gse)
  }

  nsamples <- vapply(gse, function(eset) ncol(Biobase::exprs(eset)), numeric(1))
  selected_idx <- which.max(nsamples)
  eset <- gse[[selected_idx]]

  expr <- Biobase::exprs(eset)
  pheno <- Biobase::pData(eset)
  feat <- Biobase::fData(eset)

  expr_path <- file.path(out_dir, "expression_matrix_features_x_samples.csv")
  pheno_path <- file.path(out_dir, "sample_metadata.csv")
  feat_path <- file.path(out_dir, "feature_annotation.csv")

  safe_write_csv(
    data.frame(feature_id = rownames(expr), expr, check.names = FALSE),
    expr_path
  )

  safe_write_csv(
    data.frame(sample_id = rownames(pheno), pheno, check.names = FALSE),
    pheno_path
  )

  safe_write_csv(
    data.frame(feature_id = rownames(feat), feat, check.names = FALSE),
    feat_path
  )

  candidate_cols <- find_candidate_label_columns(pheno)
  candidate_path <- file.path(out_dir, "candidate_label_columns.txt")
  writeLines(candidate_cols, candidate_path)

  manifest <- list(
    dataset_id = dataset_id,
    geo_type = "GSE",
    selected_series_index = selected_idx,
    n_series_objects = length(gse),
    n_features = nrow(expr),
    n_samples = ncol(expr),
    expression_path = expr_path,
    sample_metadata_path = pheno_path,
    feature_annotation_path = feat_path,
    candidate_label_columns = candidate_cols,
    raw_rds_path = rds_path
  )

  manifest_path <- file.path("data/manifests", paste0(dataset_id, "_manifest.json"))
  write_json(manifest, manifest_path, pretty = TRUE, auto_unbox = TRUE)

  cat("Prepared", dataset_id, "features=", nrow(expr), "samples=", ncol(expr), "\n")

  data.frame(
    dataset_id = dataset_id,
    status = "PREPARED",
    geo_type = "GSE",
    n_features = nrow(expr),
    n_samples = ncol(expr),
    selected_series_index = selected_idx,
    manifest_path = manifest_path,
    stringsAsFactors = FALSE
  )
}

prepare_gds <- function(dataset_id) {
  cat("\n=== Processing GDS:", dataset_id, "===\n")

  out_dir <- file.path("data/processed", dataset_id)
  raw_dir <- file.path("data/raw", dataset_id)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

  rds_path <- file.path(raw_dir, paste0(dataset_id, "_GEOquery_raw.rds"))

  if (file.exists(rds_path)) {
    cat("Raw RDS exists, loading:", rds_path, "\n")
    gds <- readRDS(rds_path)
  } else {
    gds <- GEOquery::getGEO(dataset_id, destdir = raw_dir)
    saveRDS(gds, rds_path)
  }

  tab <- GEOquery::Table(gds)
  cols <- GEOquery::Columns(gds)
  meta <- GEOquery::Meta(gds)

  table_path <- file.path(out_dir, "gds_table.csv")
  columns_path <- file.path(out_dir, "gds_columns.csv")
  meta_path <- file.path(out_dir, "gds_meta.json")

  safe_write_csv(tab, table_path)
  safe_write_csv(cols, columns_path)
  write_json(meta, meta_path, pretty = TRUE, auto_unbox = TRUE)

  sample_cols <- grep("^GSM", colnames(tab), value = TRUE)

  expr_path <- NA_character_
  n_features <- nrow(tab)
  n_samples <- length(sample_cols)

  if (length(sample_cols) > 0) {
    id_col <- if ("ID_REF" %in% colnames(tab)) "ID_REF" else colnames(tab)[1]
    expr <- tab[, c(id_col, sample_cols), drop = FALSE]
    colnames(expr)[1] <- "feature_id"

    expr_path <- file.path(out_dir, "expression_matrix_features_x_samples.csv")
    safe_write_csv(expr, expr_path)
  }

  candidate_cols <- find_candidate_label_columns(cols)
  candidate_path <- file.path(out_dir, "candidate_label_columns.txt")
  writeLines(candidate_cols, candidate_path)

  manifest <- list(
    dataset_id = dataset_id,
    geo_type = "GDS",
    n_features = n_features,
    n_samples_detected_from_GSM_columns = n_samples,
    gds_table_path = table_path,
    gds_columns_path = columns_path,
    gds_meta_path = meta_path,
    expression_path = expr_path,
    candidate_label_columns = candidate_cols,
    raw_rds_path = rds_path
  )

  manifest_path <- file.path("data/manifests", paste0(dataset_id, "_manifest.json"))
  write_json(manifest, manifest_path, pretty = TRUE, auto_unbox = TRUE)

  cat("Prepared", dataset_id, "features=", n_features, "samples=", n_samples, "\n")

  data.frame(
    dataset_id = dataset_id,
    status = "PREPARED",
    geo_type = "GDS",
    n_features = n_features,
    n_samples = n_samples,
    selected_series_index = NA_integer_,
    manifest_path = manifest_path,
    stringsAsFactors = FALSE
  )
}

prepare_one <- function(dataset_id) {
  tryCatch({
    if (grepl("^GSE", dataset_id, ignore.case = TRUE)) {
      prepare_gse(dataset_id)
    } else if (grepl("^GDS", dataset_id, ignore.case = TRUE)) {
      prepare_gds(dataset_id)
    } else {
      stop("Unsupported GEO id type: ", dataset_id)
    }
  }, error = function(e) {
    cat("FAILED:", dataset_id, conditionMessage(e), "\n")
    data.frame(
      dataset_id = dataset_id,
      status = "FAIL",
      geo_type = NA_character_,
      n_features = NA_integer_,
      n_samples = NA_integer_,
      selected_series_index = NA_integer_,
      manifest_path = NA_character_,
      error = conditionMessage(e),
      stringsAsFactors = FALSE
    )
  })
}

summary <- do.call(rbind, lapply(datasets$dataset_id, prepare_one))

summary_path <- "data/manifests/dataset_download_summary.csv"
data.table::fwrite(summary, summary_path)

cat("\n=== Download / preparation summary ===\n")
print(summary)

cat("\nWritten:", summary_path, "\n")
cat("=== GEO download / prepare finished ===\n")
