cat("=== AIR benchmark: dataset label audit ===\n")

suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(jsonlite))

dir.create("data/manifests", recursive = TRUE, showWarnings = FALSE)
dir.create("docs", recursive = TRUE, showWarnings = FALSE)

datasets <- read.csv("config/datasets.csv", stringsAsFactors = FALSE)

shorten <- function(x, max_chars = 180) {
  x <- as.character(x)
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("\\s+", " ", x)
  ifelse(nchar(x) > max_chars, paste0(substr(x, 1, max_chars), "..."), x)
}

summarize_column <- function(dt, dataset_id, column_name) {
  values <- dt[[column_name]]
  values_chr <- as.character(values)
  values_chr[is.na(values_chr)] <- "<NA>"

  tab <- sort(table(values_chr), decreasing = TRUE)
  tab_top <- head(tab, 15)

  data.frame(
    dataset_id = dataset_id,
    column_name = column_name,
    n_samples = nrow(dt),
    n_missing = sum(is.na(values)),
    n_unique = length(unique(values_chr)),
    top_values = paste(
      paste0(shorten(names(tab_top), 90), " [n=", as.integer(tab_top), "]"),
      collapse = " || "
    ),
    stringsAsFactors = FALSE
  )
}

candidate_columns_auto <- function(dt) {
  cols <- colnames(dt)

  keyword_patterns <- c(
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
    "control",
    "type",
    "organism",
    "sample"
  )

  keyword_hits <- unique(unlist(lapply(keyword_patterns, function(p) {
    grep(p, cols, ignore.case = TRUE, value = TRUE)
  })))

  low_cardinality_hits <- cols[vapply(cols, function(cc) {
    x <- dt[[cc]]
    if (is.numeric(x)) return(FALSE)
    ux <- unique(as.character(x))
    length(ux) >= 2 && length(ux) <= min(30, max(2, floor(nrow(dt) * 0.7)))
  }, logical(1))]

  unique(c(keyword_hits, low_cardinality_hits))
}

audit_one <- function(dataset_id) {
  cat("\n=== Auditing:", dataset_id, "===\n")

  processed_dir <- file.path("data/processed", dataset_id)

  if (!dir.exists(processed_dir)) {
    warning("Processed directory not found: ", processed_dir)
    return(NULL)
  }

  sample_metadata_path <- file.path(processed_dir, "sample_metadata.csv")
  gds_columns_path <- file.path(processed_dir, "gds_columns.csv")
  candidate_file <- file.path(processed_dir, "candidate_label_columns.txt")

  if (file.exists(sample_metadata_path)) {
    dt <- data.table::fread(sample_metadata_path, data.table = FALSE)
    metadata_type <- "GSE_sample_metadata"
  } else if (file.exists(gds_columns_path)) {
    dt <- data.table::fread(gds_columns_path, data.table = FALSE)
    metadata_type <- "GDS_columns"
  } else {
    warning("No metadata file found for ", dataset_id)
    return(NULL)
  }

  manual_candidates <- character(0)
  if (file.exists(candidate_file)) {
    manual_candidates <- readLines(candidate_file, warn = FALSE)
    manual_candidates <- manual_candidates[nzchar(manual_candidates)]
  }

  auto_candidates <- candidate_columns_auto(dt)
  candidate_cols <- unique(c(manual_candidates, auto_candidates))
  candidate_cols <- candidate_cols[candidate_cols %in% colnames(dt)]

  if (length(candidate_cols) == 0) {
    candidate_cols <- colnames(dt)
  }

  summary <- do.call(
    rbind,
    lapply(candidate_cols, function(cc) summarize_column(dt, dataset_id, cc))
  )

  summary$metadata_type <- metadata_type

  out_path <- file.path("data/manifests", paste0(dataset_id, "_label_audit.csv"))
  data.table::fwrite(summary, out_path)

  cat("Wrote:", out_path, "\n")
  summary
}

all_summaries <- do.call(
  rbind,
  lapply(datasets$dataset_id, audit_one)
)

if (is.null(all_summaries) || nrow(all_summaries) == 0) {
  stop("No label audit summaries were generated.")
}

data.table::fwrite(all_summaries, "data/manifests/label_audit_summary.csv")

template <- data.frame(
  dataset_id = datasets$dataset_id,
  final_label_column = "",
  positive_class = "",
  negative_class = "",
  include_rule = "",
  exclude_rule = "",
  n_samples_after_filtering = "",
  status = "NEEDS_MANUAL_DECISION",
  notes = "",
  stringsAsFactors = FALSE
)

data.table::fwrite(template, "data/manifests/manual_label_mapping_template.csv")

md <- c(
  "# Manual label audit",
  "",
  "This document records the manual decision process used to define binary labels for each GEO/GDS dataset.",
  "",
  "The script `scripts/02_audit_dataset_labels.R` generates candidate metadata columns and value summaries.",
  "",
  "Final class definitions must not be inferred automatically. For each dataset, the final label column, included samples, excluded samples, and class mapping must be recorded before fold generation.",
  "",
  "Generated files:",
  "",
  "- `data/manifests/label_audit_summary.csv`",
  "- `data/manifests/manual_label_mapping_template.csv`",
  "- `data/manifests/<dataset_id>_label_audit.csv`",
  "",
  "## Dataset decisions",
  ""
)

for (dataset_id in datasets$dataset_id) {
  md <- c(
    md,
    paste0("### ", dataset_id),
    "",
    "- Final label column: TBD",
    "- Positive class: TBD",
    "- Negative class: TBD",
    "- Included samples: TBD",
    "- Excluded samples: TBD",
    "- Notes: TBD",
    ""
  )
}

writeLines(md, "docs/manual_label_audit.md")

cat("\n=== Label audit summary written ===\n")
print(all_summaries[, c("dataset_id", "column_name", "n_unique", "top_values")])

cat("\nWritten:\n")
cat("data/manifests/label_audit_summary.csv\n")
cat("data/manifests/manual_label_mapping_template.csv\n")
cat("docs/manual_label_audit.md\n")
cat("=== Dataset label audit finished ===\n")
