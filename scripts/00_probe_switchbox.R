cat("=== AIR benchmark: switchBox compatibility probe ===\n")

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
  cat("Bioconductor version:", bioc_version, "\n")

  if (!requireNamespace("switchBox", quietly = TRUE)) {
    cat("Installing switchBox via BiocManager...\n")
    BiocManager::install("switchBox", ask = FALSE, update = FALSE)
  }

  if (requireNamespace("switchBox", quietly = TRUE)) {
    suppressPackageStartupMessages(library(switchBox))
    version <- as.character(utils::packageVersion("switchBox"))

    exports <- getNamespaceExports("switchBox")
    writeLines(exports, "results/runtime/switchbox_exports.txt")

    status <- "PASS"
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
  package = "switchBox",
  status = status,
  version = version,
  bioconductor_version = bioc_version,
  seconds = as.numeric(difftime(end, start, units = "secs")),
  message = message,
  stringsAsFactors = FALSE
)

print(res)
utils::write.csv(res, "results/runtime/switchbox_probe.csv", row.names = FALSE)

cat("\nIf PASS, exported functions were written to results/runtime/switchbox_exports.txt\n")
cat("=== switchBox probe finished ===\n")
