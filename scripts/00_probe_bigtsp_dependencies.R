cat("=== AIR benchmark: BigTSP dependency probe ===\n")

options(repos = c(CRAN = "https://cloud.r-project.org"))

dir.create("results/logs", recursive = TRUE, showWarnings = FALSE)
dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)

packages <- c("tree", "gbm", "randomForest")

probe_one <- function(pkg) {
  cat("\n--- Probing dependency:", pkg, "---\n")
  start <- Sys.time()

  status <- "FAIL"
  version <- NA_character_
  message <- NA_character_

  tryCatch({
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }

    if (requireNamespace(pkg, quietly = TRUE)) {
      version <- as.character(utils::packageVersion(pkg))
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

  data.frame(
    package = pkg,
    status = status,
    version = version,
    seconds = as.numeric(difftime(end, start, units = "secs")),
    message = message,
    stringsAsFactors = FALSE
  )
}

res <- do.call(rbind, lapply(packages, probe_one))
print(res)

utils::write.csv(res, "results/runtime/bigtsp_dependency_probe.csv", row.names = FALSE)

cat("=== BigTSP dependency probe finished ===\n")
