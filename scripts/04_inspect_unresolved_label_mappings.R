cat("=== AIR benchmark: inspect unresolved label mappings ===\n")

suppressPackageStartupMessages(library(data.table))

dir.create("data/manifests", recursive = TRUE, showWarnings = FALSE)
dir.create("docs", recursive = TRUE, showWarnings = FALSE)

unresolved <- c("GSE17920", "GSE3365", "GSE6613")

shorten <- function(x, max_chars = 220) {
  x <- as.character(x)
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("\\s+", " ", x)
  ifelse(nchar(x) > max_chars, paste0(substr(x, 1, max_chars), "..."), x)
}

summarize_all_columns <- function(dt, dataset_id) {
  rows <- lapply(colnames(dt), function(cc) {
    values <- as.character(dt[[cc]])
    values[is.na(values)] <- "<NA>"

    tab <- sort(table(values), decreasing = TRUE)
    tab_top <- head(tab, 20)

    data.frame(
      dataset_id = dataset_id,
      column_name = cc,
      n_samples = nrow(dt),
      n_missing = sum(is.na(dt[[cc]])),
      n_unique = length(unique(values)),
      top_values = paste(
        paste0(shorten(names(tab_top), 100), " [n=", as.integer(tab_top), "]"),
        collapse = " || "
      ),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)
}

inspect_one <- function(dataset_id) {
  cat("\n=== Inspecting:", dataset_id, "===\n")

  processed_dir <- file.path("data/processed", dataset_id)

  sample_metadata_path <- file.path(processed_dir, "sample_metadata.csv")
  gds_columns_path <- file.path(processed_dir, "gds_columns.csv")

  if (file.exists(sample_metadata_path)) {
    dt <- data.table::fread(sample_metadata_path, data.table = FALSE)
    metadata_type <- "GSE_sample_metadata"
  } else if (file.exists(gds_columns_path)) {
    dt <- data.table::fread(gds_columns_path, data.table = FALSE)
    metadata_type <- "GDS_columns"
  } else {
    stop("No metadata file found for ", dataset_id)
  }

  summary <- summarize_all_columns(dt, dataset_id)
  summary$metadata_type <- metadata_type

  out_csv <- file.path("data/manifests", paste0(dataset_id, "_all_metadata_columns.csv"))
  data.table::fwrite(summary, out_csv)

  # More readable Markdown report
  md <- c(
    paste0("# Metadata inspection: ", dataset_id),
    "",
    paste0("Metadata type: `", metadata_type, "`"),
    paste0("Samples: ", nrow(dt)),
    paste0("Columns: ", ncol(dt)),
    "",
    "## Columns with potentially useful label information",
    ""
  )

  candidate <- summary[
    summary$n_unique >= 2 &
      summary$n_unique <= min(40, max(2, floor(summary$n_samples * 0.8))),
    ,
    drop = FALSE
  ]

  # Put likely label columns first
  key <- grepl(
    "title|source|character|disease|status|group|class|phenotype|tissue|description|condition|relapse|smoking|lonely",
    candidate$column_name,
    ignore.case = TRUE
  )
  candidate <- candidate[order(!key, candidate$n_unique, candidate$column_name), ]

  for (i in seq_len(nrow(candidate))) {
    md <- c(
      md,
      paste0("### `", candidate$column_name[i], "`"),
      "",
      paste0("- Unique values: ", candidate$n_unique[i]),
      paste0("- Missing values: ", candidate$n_missing[i]),
      paste0("- Top values: ", candidate$top_values[i]),
      ""
    )
  }

  out_md <- file.path("docs", paste0(dataset_id, "_metadata_inspection.md"))
  writeLines(md, out_md)

  cat("Wrote:", out_csv, "\n")
  cat("Wrote:", out_md, "\n")

  data.frame(
    dataset_id = dataset_id,
    metadata_type = metadata_type,
    n_samples = nrow(dt),
    n_columns = ncol(dt),
    inspection_csv = out_csv,
    inspection_md = out_md,
    stringsAsFactors = FALSE
  )
}

res <- do.call(rbind, lapply(unresolved, inspect_one))

data.table::fwrite(res, "data/manifests/unresolved_label_inspection_summary.csv")

cat("\n=== Unresolved label inspection summary ===\n")
print(res)
cat("=== Inspection finished ===\n")
