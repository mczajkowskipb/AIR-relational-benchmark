cat("=== Initializing renv for AIR relational benchmark ===\n")

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}

if (!file.exists("renv.lock")) {
  renv::init(bare = TRUE)
} else {
  cat("renv.lock already exists; skipping renv::init().\n")
}

cat("R version:\n")
print(R.version.string)

cat("Library paths:\n")
print(.libPaths())

cat("renv status:\n")
print(renv::status())

cat("=== renv initialization finished ===\n")
