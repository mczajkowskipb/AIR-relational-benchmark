fit_predict_ranktreeensemble_rforest <- function(
  x_train,
  y_train,
  x_test,
  y_test,
  config = list()
) {
  method_id <- if (!is.null(config$method_id)) config$method_id else "rrf_ranktreeensemble"
  ntree <- if (!is.null(config$ntree)) config$ntree else 50
  seed <- if (!is.null(config$seed)) config$seed else 123
  extract_rules_flag <- if (!is.null(config$extract_rules)) config$extract_rules else FALSE

  start_train <- Sys.time()

  y_train <- factor(y_train)
  y_test <- factor(y_test, levels = levels(y_train))

  if (length(levels(y_train)) != 2) {
    stop("ranktreeEnsemble rforest wrapper currently supports exactly two classes.")
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

  if (is.null(rownames(x_test))) {
    rownames(x_test) <- paste0("test_sample_", seq_len(nrow(x_test)))
  }

  original_features <- colnames(x_train)
  safe_features <- make.names(paste0("F_", seq_along(original_features)), unique = TRUE)

  colnames(x_train) <- safe_features
  colnames(x_test) <- safe_features

  train_df <- data.frame(
    class_label = y_train,
    as.data.frame(x_train, check.names = FALSE),
    check.names = FALSE
  )

  test_df <- as.data.frame(x_test, check.names = FALSE)

  fit <- ranktreeEnsemble::rforest(
    class_label ~ .,
    data = train_df,
    ntree = ntree,
    seed = seed,
    importance = TRUE
  )

  end_train <- Sys.time()

  start_predict <- Sys.time()

  pred_obj <- predict(fit, test_df)

  if (is.null(pred_obj$label)) {
    stop("ranktreeEnsemble predict() did not return a 'label' field.")
  }

  pred <- factor(pred_obj$label, levels = levels(y_train))

  # rforest returns labels; do not invent calibrated probabilities.
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

  rules_n <- NA_integer_
  rules_status <- "not_requested"

  if (isTRUE(extract_rules_flag)) {
    rules_obj <- tryCatch({
      ranktreeEnsemble::extract.rules(fit, subtrees = 3, treedepth = 2)
    }, error = function(e) {
      rules_status <<- paste0("failed: ", conditionMessage(e))
      NULL
    })

    if (!is.null(rules_obj) && !is.null(rules_obj$rule)) {
      rules_n <- nrow(rules_obj$rule)
      rules_status <- "extracted"
    }
  }

  runtime <- make_runtime_table(
    method_id = method_id,
    train_seconds = as.numeric(difftime(end_train, start_train, units = "secs")),
    predict_seconds = as.numeric(difftime(end_predict, start_predict, units = "secs"))
  )

  model_info <- make_model_info(
    method_id = method_id,
    model_size = ntree,
    n_features_used = ncol(x_train),
    n_relations_used = NA_integer_,
    notes = paste0(
      "ranktreeEnsemble_rforest; ntree=", ntree,
      "; seed=", seed,
      "; safe_feature_names=TRUE",
      "; rules_status=", rules_status,
      "; rules_n=", rules_n
    )
  )

  model <- list(
    fit = fit,
    original_features = original_features,
    safe_features = safe_features,
    positive = positive,
    levels = levels(y_train)
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
