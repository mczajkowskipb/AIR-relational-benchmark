# Majority class baseline.
#
# Interface:
# fit_predict_majority(x_train, y_train, x_test, y_test, config)
#
# X matrices are accepted for interface consistency but not used for fitting.

fit_predict_majority <- function(
  x_train,
  y_train,
  x_test,
  y_test,
  config = list()
) {
  method_id <- "majority"

  start_train <- Sys.time()

  y_train <- factor(y_train)
  y_test <- factor(y_test, levels = levels(y_train))

  if (length(levels(y_train)) != 2) {
    stop("Majority baseline currently supports exactly two classes.")
  }

  positive <- if (!is.null(config$positive)) {
    config$positive
  } else {
    levels(y_train)[2]
  }

  class_counts <- table(y_train)
  max_count <- max(class_counts)
  majority_candidates <- names(class_counts)[class_counts == max_count]

  # Deterministic tie-break: first class level.
  majority_class <- levels(y_train)[levels(y_train) %in% majority_candidates][1]

  positive_prevalence <- mean(y_train == positive)

  end_train <- Sys.time()

  start_predict <- Sys.time()

  pred <- factor(
    rep(majority_class, length(y_test)),
    levels = levels(y_train)
  )

  # Constant score for positive class based only on train prevalence.
  score <- rep(positive_prevalence, length(y_test))

  sample_id <- make_sample_ids(x_test, prefix = "test_sample")

  predictions <- make_prediction_table(
    sample_id = sample_id,
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
    n_features_used = 0L,
    n_relations_used = 0L,
    notes = paste0(
      "majority_class=", majority_class,
      "; positive=", positive,
      "; positive_train_prevalence=", round(positive_prevalence, 6)
    )
  )

  result <- list(
    predictions = predictions,
    metrics = metrics,
    model_info = model_info,
    runtime = runtime
  )

  validate_method_result(result)

  result
}
