cat("=== AIR benchmark: collect smoke summaries ===\n")

suppressPackageStartupMessages(library(data.table))

dir.create("results/summary", recursive = TRUE, showWarnings = FALSE)

files <- list.files(
  "results/metrics",
  pattern = "^smoke_2x2__.*__summary\\.csv$",
  full.names = TRUE
)

if (length(files) == 0) {
  stop("No smoke summary files found in results/metrics.")
}

read_one <- function(path) {
  x <- data.table::fread(path, data.table = FALSE)
  base <- basename(path)
  method_id <- sub("^smoke_2x2__(.*)__summary\\.csv$", "\\1", base)
  x$method_id <- method_id
  x$protocol_id <- "smoke_2x2"
  x
}

summary <- data.table::rbindlist(lapply(files, read_one), fill = TRUE)

summary <- summary[
  order(summary$dataset_id, summary$method_id),
  ,
  drop = FALSE
]

out_path <- "results/summary/smoke_2x2_all_methods_summary.csv"
data.table::fwrite(summary, out_path)

cat("Written:", out_path, "\n")
print(summary)

cat("=== Smoke summary collection finished ===\n")
