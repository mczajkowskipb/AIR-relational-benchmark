cat("=== AIR benchmark: GEOquery compatibility probe ===\n")

options(repos = c(CRAN = "https://cloud.r-project.org"))

dir.create("results/logs", recursive = TRUE, showWarnings = FALSE)
dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)

status <- "FAIL"
version <- NA_character_
message <- NA_character_
bioc_version <- NA_character_

start <- Sys.time()

tryCatch({
  if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager", repos = "https://cloud.r-project.org")
  }

  bioc_version <- as.character(BiocManager::version())

  if (!requireNamespace("GEOquery", quietly = TRUE)) {
    BiocManager::install("GEOquery", ask = FALSE, update = FALSE)
  }

  if (requireNamespace("GEOquery", quietly = TRUE)) {
    suppressPackageStartupMessages(library(GEOquery))
    version <- as.character(utils::packageVersion("GEOquery"))

    exports <- getNamespaceExports("GEOquery")
    writeLines(exports, "results/runtime/geoquery_exports.txt")

    status <- "PASS_ENV"
    message <- "installed_and_loadable"
  } else {
    status <- "FAIL"
    message <- "not_loadable_after_install"
  }

}, error = function(e) {
  status <<- "FAIL"
  message <<- conditionMessage(e)
})

end <- Sys.time()

res <- data.frame(
  package = "GEOquery",
  status = status,
  version = version,
  bioconductor_version = bioc_version,
  seconds = as.numeric(difftime(end, start, units = "secs")),
  message = message,
  stringsAsFactors = FALSE
)

print(res)
write.csv(res, "results/runtime/geoquery_probe.csv", row.names = FALSE)

cat("=== GEOquery probe finished ===\n")
