cat("=== AIR benchmark: R package compatibility probe ===\n")

options(repos = c(CRAN = "https://cloud.r-project.org"))

dir.create("results/logs", recursive = TRUE, showWarnings = FALSE)
dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)

packages <- data.frame(
  package = c(
    "data.table",
    "dplyr",
    "yaml",
    "jsonlite",
    "caret",
    "pROC",
    "MLmetrics",
    "glmnet",
    "e1071",
    "ranger",
    "xgboost",
    "doParallel",
    "foreach",
    "BiocManager"
  ),
  source = c(
    rep("CRAN", 14)
  ),
  stringsAsFactors = FALSE
)

probe_one <- function(pkg) {
  cat("\n--- Probing package:", pkg, "---\n")
  start <- Sys.time()

  status <- "FAIL"
  version <- NA_character_
  message <- NA_character_

  tryCatch({
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }

    suppressPackageStartupMessages(
      ok <- requireNamespace(pkg, quietly = TRUE)
    )

    if (isTRUE(ok)) {
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

res <- do.call(rbind, lapply(packages$package, probe_one))

print(res)

out <- "results/runtime/r_package_probe.csv"
utils::write.csv(res, out, row.names = FALSE)

cat("\nWritten:", out, "\n")
cat("=== R package probe finished ===\n")
