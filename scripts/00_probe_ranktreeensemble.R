cat("=== AIR benchmark: ranktreeEnsemble compatibility probe ===\n")

options(repos = c(CRAN = "https://cloud.r-project.org"))

dir.create("results/logs", recursive = TRUE, showWarnings = FALSE)
dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)

status <- "FAIL"
version <- NA_character_
message <- NA_character_

start <- Sys.time()

tryCatch({
  if (!requireNamespace("ranktreeEnsemble", quietly = TRUE)) {
    install.packages("ranktreeEnsemble", repos = "https://cloud.r-project.org")
  }

  if (requireNamespace("ranktreeEnsemble", quietly = TRUE)) {
    suppressPackageStartupMessages(library(ranktreeEnsemble))

    version <- as.character(utils::packageVersion("ranktreeEnsemble"))

    exports <- getNamespaceExports("ranktreeEnsemble")
    writeLines(exports, "results/runtime/ranktreeensemble_exports.txt")

    cat("Package exports:\n")
    print(exports)

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
  package = "ranktreeEnsemble",
  status = status,
  version = version,
  seconds = as.numeric(difftime(end, start, units = "secs")),
  message = message,
  stringsAsFactors = FALSE
)

print(res)
write.csv(res, "results/runtime/ranktreeensemble_probe.csv", row.names = FALSE)

cat("=== ranktreeEnsemble probe finished ===\n")
