fit_predict_internal_tsp <- function(
  x_train,
  y_train,
  x_test,
  y_test,
  config = list()
) {
  method_id <- if (!is.null(config$method_id)) config$method_id else "switchbox_tsp"

  start_train <- Sys.time()

  y_train <- factor(y_train)
  y_test <- factor(y_test, levels = levels(y_train))

  if (length(levels(y_train)) != 2) {
    stop("TSP wrapper currently supports exactly two classes.")
  }

  positive <- if (!is.null(config$positive)) {
    config$positive
  } else {
    levels(y_train)[2]
  }

  negative <- setdiff(levels(y_train), positive)

  x_train <- as.matrix(x_train)
  x_test <- as.matrix(x_test)

  p <- ncol(x_train)
  if (p < 2) {
    stop("TSP requires at least two features.")
  }

  best_score <- -Inf
  best_i <- NA_integer_
  best_j <- NA_integer_
  best_direction <- NA_character_

  y_pos <- y_train == positive
  y_neg <- y_train == negative

  for (i in seq_len(p - 1)) {
    xi <- x_train[, i]
    for (j in (i + 1):p) {
      rel <- xi > x_train[, j]

      p_pos <- mean(rel[y_pos], na.rm = TRUE)
      p_neg <- mean(rel[y_neg], na.rm = TRUE)

      diff <- p_pos - p_neg
      score <- abs(diff)

      if (is.finite(score) && score > best_score) {
        best_score <- score
        best_i <- i
        best_j <- j
        best_direction <- ifelse(diff >= 0, "gt_positive", "gt_negative")
      }
    }
  }

  feature_i <- colnames(x_train)[best_i]
  feature_j <- colnames(x_train)[best_j]

  end_train <- Sys.time()

  start_predict <- Sys.time()

  rel_test <- x_test[, best_i] > x_test[, best_j]

  pred_chr <- if (best_direction == "gt_positive") {
    ifelse(rel_test, positive, negative)
  } else {
    ifelse(rel_test, negative, positive)
  }

  pred <- factor(pred_chr, levels = levels(y_train))

  # TSP returns hard labels; no calibrated probability is provided.
  score <- rep(NA_real_, length(y_test))

  predictions <- make_prediction_table(
    sample_id = make_sample_ids(x_test, prefix = "test_sample"),
    truth = y_test,
    pred = pred,
    score = score,
    positive = positive
  )

  metrics <- compute_binary_metrics(
    truth = y_test,
    pred = pred,
    score = score,
    positive = positive
  )

  end_predict <- Sys.time()

  runtime <- make_runtime_table(
    method_id = method_id,
    train_seconds = as.numeric(difftime(end_train, start_train, units = "secs")),
    predict_seconds = as.numeric(difftime(end_predict, start_predict, units = "secs"))
  )

  model_info <- make_model_info(
    method_id = method_id,
    model_size = 1L,
    n_features_used = 2L,
    n_relations_used = 1L,
    notes = paste0(
      "internal_TSP; feature_i=", feature_i,
      "; feature_j=", feature_j,
      "; direction=", best_direction,
      "; score=", round(best_score, 6)
    )
  )

  model <- list(
    method = "internal_TSP",
    feature_i = feature_i,
    feature_j = feature_j,
    i = best_i,
    j = best_j,
    direction = best_direction,
    score = best_score,
    positive = positive,
    negative = negative
  )

  result <- list(
    predictions = predictions,
    metrics = metrics,
    model_info = model_info,
    runtime = runtime,
    model = model
  )

  validate_method_result(result)
  result
}

fit_predict_switchbox_ktsp <- function(
  x_train,
  y_train,
  x_test,
  y_test,
  config = list()
) {
  method_id <- if (!is.null(config$method_id)) config$method_id else "switchbox_ktsp"
  krange <- if (!is.null(config$krange)) config$krange else c(3, 5, 7)

  start_train <- Sys.time()

  y_train <- factor(y_train)
  y_test <- factor(y_test, levels = levels(y_train))

  if (length(levels(y_train)) != 2) {
    stop("switchBox wrapper currently supports exactly two classes.")
  }

  positive <- if (!is.null(config$positive)) {
    config$positive
  } else {
    levels(y_train)[2]
  }

  if (is.null(colnames(x_train))) {
    stop("x_train must have feature names as colnames.")
  }

  if (is.null(rownames(x_train))) {
    rownames(x_train) <- paste0("train_sample_", seq_len(nrow(x_train)))
  }

  if (is.null(rownames(x_test))) {
    rownames(x_test) <- paste0("test_sample_", seq_len(nrow(x_test)))
  }

  # switchBox expects features x samples.
  train_mat <- t(as.matrix(x_train))
  test_mat <- t(as.matrix(x_test))

  fit <- switchBox::SWAP.Train.KTSP(
    inputMat = train_mat,
    phenoGroup = y_train,
    krange = krange
  )

  end_train <- Sys.time()

  start_predict <- Sys.time()

  pred <- switchBox::SWAP.KTSP.Classify(
    inputMat = test_mat,
    classifier = fit
  )

  pred <- factor(pred, levels = levels(y_train))

  # switchBox returns hard labels here; no invented probabilities.
  score <- rep(NA_real_, length(y_test))

  predictions <- make_prediction_table(
    sample_id = make_sample_ids(x_test, prefix = "test_sample"),
    truth = y_test,
    pred = pred,
    score = score,
    positive = positive
  )

  metrics <- compute_binary_metrics(
    truth = y_test,
    pred = pred,
    score = score,
    positive = positive
  )

  end_predict <- Sys.time()

  n_relations <- if (!is.null(fit$TSPs)) {
    if (is.matrix(fit$TSPs)) nrow(fit$TSPs) else length(fit$TSPs) / 2
  } else {
    NA_integer_
  }

  runtime <- make_runtime_table(
    method_id = method_id,
    train_seconds = as.numeric(difftime(end_train, start_train, units = "secs")),
    predict_seconds = as.numeric(difftime(end_predict, start_predict, units = "secs"))
  )

  model_info <- make_model_info(
    method_id = method_id,
    model_size = n_relations,
    n_features_used = ncol(x_train),
    n_relations_used = n_relations,
    notes = paste0(
      "switchBox_SWAPR_Train_KTSP; krange=", paste(krange, collapse = ";"),
      "; classifier_name=", ifelse(is.null(fit$name), NA_character_, fit$name)
    )
  )

  result <- list(
    predictions = predictions,
    metrics = metrics,
    model_info = model_info,
    runtime = runtime,
    model = fit
  )

  validate_method_result(result)
  result
}
