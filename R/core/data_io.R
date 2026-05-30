load_final_dataset <- function(dataset_id) {
  x_path <- file.path("data/final", dataset_id, "X_features_x_samples.csv")
  y_path <- file.path("data/final", dataset_id, "y.csv")

  if (!file.exists(x_path)) {
    stop("Missing X file: ", x_path)
  }
  if (!file.exists(y_path)) {
    stop("Missing y file: ", y_path)
  }

  x_raw <- data.table::fread(x_path, data.table = FALSE)
  y <- data.table::fread(y_path, data.table = FALSE)

  if (!"feature_id" %in% colnames(x_raw)) {
    stop("X file must contain feature_id column.")
  }

  feature_id <- x_raw$feature_id
  x_mat <- as.matrix(x_raw[, setdiff(colnames(x_raw), "feature_id"), drop = FALSE])
  rownames(x_mat) <- feature_id

  # Convert features x samples -> samples x features
  x <- t(x_mat)

  # Force numeric matrix
  storage.mode(x) <- "numeric"

  missing_samples <- setdiff(y$sample_id, rownames(x))
  if (length(missing_samples) > 0) {
    stop("Some y samples are missing in X: ", paste(head(missing_samples, 10), collapse = ", "))
  }

  x <- x[y$sample_id, , drop = FALSE]
  y$class_label <- factor(y$class_label)

  list(
    dataset_id = dataset_id,
    x = x,
    y = y,
    class_label = y$class_label,
    sample_id = y$sample_id
  )
}

load_fold_table <- function(protocol_id, dataset_id) {
  fold_path <- file.path("data/folds", paste0(protocol_id, "__", dataset_id, ".csv"))

  if (!file.exists(fold_path)) {
    stop("Missing fold file: ", fold_path)
  }

  data.table::fread(fold_path, data.table = FALSE)
}

get_fold_split <- function(dataset, fold_table, repeat_id, fold_id) {
  fold_sub <- fold_table[
    fold_table$repeat_id == repeat_id & fold_table$fold_id == fold_id,
    ,
    drop = FALSE
  ]

  if (nrow(fold_sub) == 0) {
    stop("No rows for repeat=", repeat_id, ", fold=", fold_id)
  }

  train_ids <- fold_sub$sample_id[fold_sub$split == "train"]
  test_ids <- fold_sub$sample_id[fold_sub$split == "test"]

  missing_train <- setdiff(train_ids, rownames(dataset$x))
  missing_test <- setdiff(test_ids, rownames(dataset$x))

  if (length(missing_train) > 0) {
    stop("Train samples missing in X: ", paste(head(missing_train, 10), collapse = ", "))
  }

  if (length(missing_test) > 0) {
    stop("Test samples missing in X: ", paste(head(missing_test, 10), collapse = ", "))
  }

  y_named <- dataset$class_label
  names(y_named) <- dataset$sample_id

  list(
    x_train = dataset$x[train_ids, , drop = FALSE],
    y_train = droplevels(y_named[train_ids]),
    x_test = dataset$x[test_ids, , drop = FALSE],
    y_test = droplevels(y_named[test_ids]),
    train_ids = train_ids,
    test_ids = test_ids
  )
}
