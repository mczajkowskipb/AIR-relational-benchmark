cat("=== AIR benchmark: BigTSP compatibility probe ===\n")

options(repos = c(CRAN = "https://cloud.r-project.org"))

dir.create("results/logs", recursive = TRUE, showWarnings = FALSE)
dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)

status <- "FAIL"
version <- NA_character_
message <- NA_character_
install_source <- NA_character_

start <- Sys.time()

try_install_bigtsp <- function() {
  if (requireNamespace("BigTSP", quietly = TRUE)) {
    install_source <<- "already_installed"
    return(TRUE)
  }

  cat("Trying install.packages('BigTSP') from CRAN...\n")
  ok <- tryCatch({
    install.packages("BigTSP", repos = "https://cloud.r-project.org")
    requireNamespace("BigTSP", quietly = TRUE)
  }, error = function(e) {
    cat("CRAN install failed:", conditionMessage(e), "\n")
    FALSE
  })

  if (isTRUE(ok)) {
    install_source <<- "CRAN"
    return(TRUE)
  }

  cat("Trying BigTSP 1.0 from CRAN archive...\n")
  archive_url <- "https://cran.r-project.org/src/contrib/Archive/BigTSP/BigTSP_1.0.tar.gz"

  ok <- tryCatch({
    install.packages(archive_url, repos = NULL, type = "source")
    requireNamespace("BigTSP", quietly = TRUE)
  }, error = function(e) {
    cat("Archive install failed:", conditionMessage(e), "\n")
    FALSE
  })

  if (isTRUE(ok)) {
    install_source <<- "CRAN_archive_BigTSP_1.0"
    return(TRUE)
  }

  FALSE
}

tryCatch({
  ok <- try_install_bigtsp()

  if (isTRUE(ok)) {
    suppressPackageStartupMessages(library(BigTSP))
    version <- as.character(utils::packageVersion("BigTSP"))

    exports <- getNamespaceExports("BigTSP")
    writeLines(exports, "results/runtime/bigtsp_exports.txt")

    has_tsp_tree <- "tsp.tree" %in% exports
    has_predict <- any(grepl("predict", exports))

    cat("Has tsp.tree:", has_tsp_tree, "\n")
    cat("Any exported predict-like function:", has_predict, "\n")

    if (has_tsp_tree) {
      status <- "PASS"
      message <- "installed_loadable_and_tsp.tree_exported"
    } else {
      status <- "PARTIAL"
      message <- "installed_loadable_but_tsp.tree_not_exported"
    }
  } else {
    status <- "FAIL"
    message <- "BigTSP_not_installable"
  }

}, error = function(e) {
  status <<- "FAIL"
  message <<- conditionMessage(e)
})

end <- Sys.time()

res <- data.frame(
  package = "BigTSP",
  status = status,
  version = version,
  install_source = install_source,
  seconds = as.numeric(difftime(end, start, units = "secs")),
  message = message,
  stringsAsFactors = FALSE
)

print(res)
utils::write.csv(res, "results/runtime/bigtsp_probe.csv", row.names = FALSE)

cat("\nIf installed, exported functions were written to results/runtime/bigtsp_exports.txt\n")
cat("=== BigTSP probe finished ===\n")
