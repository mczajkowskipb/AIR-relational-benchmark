cat("=== Make TSPDT f100 grid ===\n")

dir.create("results/tspdt_f100", recursive = TRUE, showWarnings = FALSE)

protocol <- "cv_5x5_tspdt_f100"
datasets <- sort(gsub(
  paste0("^", protocol, "__|\\.csv$"),
  "",
  basename(list.files("data/folds", pattern = paste0("^", protocol, "__.*\\.csv$"), full.names = TRUE))
))

cmds <- c()
job <- 0

for (dataset_id in datasets) {
  folds <- read.csv(file.path("data/folds", paste0(protocol, "__", dataset_id, ".csv")))
  combos <- unique(folds[, c("repeat_id", "fold_id")])

  for (i in seq_len(nrow(combos))) {
    job <- job + 1
    cmds <- c(cmds, paste(
      "Rscript scripts/10_run_single_job.R",
      paste0("--protocol=", protocol),
      paste0("--dataset=", dataset_id),
      "--method=tspdt_bigtsp",
      paste0("--repeat=", combos$repeat_id[i]),
      paste0("--fold=", combos$fold_id[i]),
      "--n_features=100"
    ))
  }
}

writeLines(cmds, "results/tspdt_f100/tspdt_f100_commands.txt")
cat("Jobs:", length(cmds), "\n")
cat("Written: results/tspdt_f100/tspdt_f100_commands.txt\n")
