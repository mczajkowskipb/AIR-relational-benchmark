args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) return(default)
  sub(paste0("^--", name, "="), "", hit[1])
}

dataset_id <- get_arg("dataset")
protocol_id <- get_arg("protocol", "cv_10x10")
method_id <- get_arg("method")
repeat_id <- as.integer(get_arg("repeat"))
fold_id <- as.integer(get_arg("fold"))
n_features <- as.integer(get_arg("n_features", "200"))

if (is.null(dataset_id) || is.null(method_id) || is.na(repeat_id) || is.na(fold_id)) {
  stop("Required args: --dataset=ID --method=METHOD --repeat=N --fold=N")
}

cat("=== AIR single job ===\n")
cat("dataset:", dataset_id, "\n")
cat("protocol:", protocol_id, "\n")
cat("method:", method_id, "\n")
cat("repeat:", repeat_id, "\n")
cat("fold:", fold_id, "\n")
cat("n_features:", n_features, "\n")

suppressPackageStartupMessages(library(data.table))

source("R/core/data_io.R")
source("R/core/preprocessing.R")
source("R/core/metrics.R")
source("R/core/model_interface.R")

if (method_id == "majority") {
  source("R/methods/method_majority.R")
} else if (method_id %in% c("switchbox_tsp", "switchbox_ktsp")) {
  suppressPackageStartupMessages(library(switchBox))
  source("R/methods/method_switchbox.R")
} else if (method_id == "tspdt_bigtsp") {
  suppressPackageStartupMessages(library(BigTSP))
  suppressPackageStartupMessages(library(tree))
  source("R/methods/method_bigtsp.R")
} else if (method_id == "rrf_ranktreeensemble") {
  suppressPackageStartupMessages(library(ranktreeEnsemble))
  source("R/methods/method_ranktreeensemble.R")
} else {
  stop("Unsupported method_id: ", method_id)
}

dir.create("results/jobs", recursive = TRUE, showWarnings = FALSE)
dir.create("results/jobs/predictions", recursive = TRUE, showWarnings = FALSE)
dir.create("results/jobs/metrics", recursive = TRUE, showWarnings = FALSE)
dir.create("results/jobs/model_info", recursive = TRUE, showWarnings = FALSE)
dir.create("results/jobs/runtime", recursive = TRUE, showWarnings = FALSE)
dir.create("results/jobs/selected_features", recursive = TRUE, showWarnings = FALSE)
dir.create("results/jobs/models", recursive = TRUE, showWarnings = FALSE)
dir.create("results/jobs/logs", recursive = TRUE, showWarnings = FALSE)

job_id <- paste(protocol_id, dataset_id, method_id, paste0("r", repeat_id), paste0("f", fold_id), sep = "__")

done_path <- file.path("results/jobs", paste0(job_id, ".done"))
fail_path <- file.path("results/jobs", paste0(job_id, ".fail"))

if (file.exists(done_path)) {
  cat("Job already done:", job_id, "\n")
  quit(save = "no", status = 0)
}

start_total <- Sys.time()

status <- "FAIL"
message <- NA_character_

tryCatch({
  ds <- load_final_dataset(dataset_id)
  folds <- load_fold_table(protocol_id, dataset_id)
  split <- get_fold_split(ds, folds, repeat_id, fold_id)

  prep <- fit_preprocessing(
    split$x_train,
    feature_filter = "mad",
    n_features = min(n_features, ncol(split$x_train)),
    impute = TRUE,
    scale = FALSE
  )

  x_train_p <- apply_preprocessing(split$x_train, prep)
  x_test_p <- apply_preprocessing(split$x_test, prep)

  positive <- levels(split$y_train)[2]

  if (method_id == "majority") {
    res <- fit_predict_majority(
      x_train = x_train_p,
      y_train = split$y_train,
      x_test = x_test_p,
      y_test = split$y_test,
      config = list(positive = positive)
    )
  } else if (method_id == "switchbox_tsp") {
    res <- fit_predict_internal_tsp(
      x_train = x_train_p,
      y_train = split$y_train,
      x_test = x_test_p,
      y_test = split$y_test,
      config = list(method_id = method_id, positive = positive)
    )
  } else if (method_id == "switchbox_ktsp") {
    res <- fit_predict_switchbox_ktsp(
      x_train = x_train_p,
      y_train = split$y_train,
      x_test = x_test_p,
      y_test = split$y_test,
      config = list(method_id = method_id, positive = positive, krange = c(3, 5, 7))
    )
  } else if (method_id == "tspdt_bigtsp") {
    res <- fit_predict_bigtsp_tspdt(
      x_train = x_train_p,
      y_train = split$y_train,
      x_test = x_test_p,
      y_test = split$y_test,
      config = list(
        method_id = method_id,
        positive = positive,
        mincut = 2,
        minsize = 5,
        mindev = 0.001
      )
    )
  } else if (method_id == "rrf_ranktreeensemble") {
    res <- fit_predict_ranktreeensemble_rforest(
      x_train = x_train_p,
      y_train = split$y_train,
      x_test = x_test_p,
      y_test = split$y_test,
      config = list(
        method_id = method_id,
        positive = positive,
        ntree = 50,
        seed = 20260530 + repeat_id * 100 + fold_id,
        extract_rules = FALSE
      )
    )
  }

  res$predictions$dataset_id <- dataset_id
  res$predictions$protocol_id <- protocol_id
  res$predictions$method_id <- method_id
  res$predictions$repeat_id <- repeat_id
  res$predictions$fold_id <- fold_id

  res$metrics$dataset_id <- dataset_id
  res$metrics$protocol_id <- protocol_id
  res$metrics$method_id <- method_id
  res$metrics$repeat_id <- repeat_id
  res$metrics$fold_id <- fold_id

  res$model_info$dataset_id <- dataset_id
  res$model_info$protocol_id <- protocol_id
  res$model_info$repeat_id <- repeat_id
  res$model_info$fold_id <- fold_id

  res$runtime$dataset_id <- dataset_id
  res$runtime$protocol_id <- protocol_id
  res$runtime$repeat_id <- repeat_id
  res$runtime$fold_id <- fold_id

  selected_table <- prep$selected_table
  selected_table$dataset_id <- dataset_id
  selected_table$protocol_id <- protocol_id
  selected_table$method_id <- method_id
  selected_table$repeat_id <- repeat_id
  selected_table$fold_id <- fold_id

  data.table::fwrite(res$predictions, file.path("results/jobs/predictions", paste0(job_id, ".csv")))
  data.table::fwrite(res$metrics, file.path("results/jobs/metrics", paste0(job_id, ".csv")))
  data.table::fwrite(res$model_info, file.path("results/jobs/model_info", paste0(job_id, ".csv")))
  data.table::fwrite(res$runtime, file.path("results/jobs/runtime", paste0(job_id, ".csv")))
  data.table::fwrite(selected_table, file.path("results/jobs/selected_features", paste0(job_id, ".csv")))

  if (!is.null(res$model)) {
    saveRDS(res$model, file.path("results/jobs/models", paste0(job_id, ".rds")))
  }

  status <- "DONE"
  message <- "ok"

}, error = function(e) {
  status <<- "FAIL"
  message <<- conditionMessage(e)
})

end_total <- Sys.time()

job_status <- data.frame(
  job_id = job_id,
  dataset_id = dataset_id,
  protocol_id = protocol_id,
  method_id = method_id,
  repeat_id = repeat_id,
  fold_id = fold_id,
  n_features = n_features,
  status = status,
  message = message,
  total_seconds = as.numeric(difftime(end_total, start_total, units = "secs")),
  stringsAsFactors = FALSE
)

status_path <- if (status == "DONE") done_path else fail_path
data.table::fwrite(job_status, status_path)

print(job_status)

if (status != "DONE") {
  quit(save = "no", status = 1)
}

cat("=== AIR single job finished ===\n")
