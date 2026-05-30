fit_predict_bigtsp_tspdt <- function(
  x_train,
  y_train,
  x_test,
  y_test,
  config = list()
) {
  method_id <- if (!is.null(config$method_id)) config$method_id else "tspdt_bigtsp"

  start_train <- Sys.time()

  y_train <- factor(y_train)
  y_test <- factor(y_test, levels = levels(y_train))

  if (length(levels(y_train)) != 2) {
    stop("BigTSP tsp.tree wrapper currently supports exactly two classes.")
  }

  positive <- if (!is.null(config$positive)) {
    config$positive
  } else {
    levels(y_train)[2]
  }

  x_train <- as.matrix(x_train)
  x_test <- as.matrix(x_test)

  if (is.null(colnames(x_train))) {
    colnames(x_train) <- paste0("feature_", seq_len(ncol(x_train)))
  }

  if (is.null(colnames(x_test))) {
    colnames(x_test) <- colnames(x_train)
  }

  if (is.null(rownames(x_test))) {
    rownames(x_test) <- paste0("test_sample_", seq_len(nrow(x_test)))
  }

  mincut <- if (!is.null(config$mincut)) config$mincut else 2
  minsize <- if (!is.null(config$minsize)) config$minsize else 5
  mindev <- if (!is.null(config$mindev)) config$mindev else 0.001

  fit <- BigTSP::tsp.tree(
    X = x_train,
    response = y_train,
    control = tree::tree.control(
      nobs = nrow(x_train),
      mincut = mincut,
      minsize = minsize,
      mindev = mindev
    )
  )

  end_train <- Sys.time()

  start_predict <- Sys.time()

  # BigTSP::predict.tsp.tree expects newdata with response in column 1
  # and features from column 2 onward. The response is ignored for feature
  # construction but required by the legacy API.
  test_newdata <- data.frame(response = y_test, x_test, check.names = FALSE)

  pred <- predict(fit, newdata = test_newdata, type = "class")
  pred <- factor(pred, levels = levels(y_train))

  # BigTSP tsp.tree returns hard class labels here; no calibrated probabilities.
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

  tree_nodes <- tryCatch(nrow(fit$frame), error = function(e) NA_integer_)
  terminal_nodes <- tryCatch(sum(fit$frame$var == "<leaf>"), error = function(e) NA_integer_)

  runtime <- make_runtime_table(
    method_id = method_id,
    train_seconds = as.numeric(difftime(end_train, start_train, units = "secs")),
    predict_seconds = as.numeric(difftime(end_predict, start_predict, units = "secs"))
  )

  model_info <- make_model_info(
    method_id = method_id,
    model_size = tree_nodes,
    n_features_used = ncol(x_train),
    n_relations_used = NA_integer_,
    notes = paste0(
      "BigTSP_tsp.tree; tree_nodes=", tree_nodes,
      "; terminal_nodes=", terminal_nodes,
      "; mincut=", mincut,
      "; minsize=", minsize,
      "; mindev=", mindev,
      "; predict_requires_response_column=TRUE"
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
