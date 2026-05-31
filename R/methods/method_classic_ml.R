sanitize_xy_for_classic <- function(x_train, x_test) {
  x_train <- as.matrix(x_train)
  x_test <- as.matrix(x_test)

  storage.mode(x_train) <- "numeric"
  storage.mode(x_test) <- "numeric"

  safe_features <- paste0("F_", seq_len(ncol(x_train)))
  colnames(x_train) <- safe_features
  colnames(x_test) <- safe_features

  list(x_train = x_train, x_test = x_test, safe_features = safe_features)
}

fit_predict_glmnet_enet <- function(x_train, y_train, x_test, y_test, config = list()) {
  method_id <- "glmnet_enet"
  xx <- sanitize_xy_for_classic(x_train, x_test)
  x_train <- xx$x_train
  x_test <- xx$x_test

  start_train <- Sys.time()
  y_train <- factor(as.character(y_train))
  y_test <- factor(as.character(y_test), levels = levels(y_train))
  positive <- if (!is.null(config$positive)) config$positive else levels(y_train)[2]
  y01 <- as.numeric(y_train == positive)

  set.seed(if (!is.null(config$seed)) config$seed else 123)
  nfolds <- max(3, min(5, min(table(y_train))))

  fit <- glmnet::cv.glmnet(
    x = x_train,
    y = y01,
    family = "binomial",
    alpha = 0.5,
    nfolds = nfolds,
    type.measure = "deviance"
  )

  end_train <- Sys.time()
  start_predict <- Sys.time()

  score <- as.numeric(predict(fit, newx = x_test, s = "lambda.min", type = "response"))
  pred <- factor(ifelse(score >= 0.5, positive, setdiff(levels(y_train), positive)), levels = levels(y_train))

  predictions <- make_prediction_table(make_sample_ids(x_test), y_test, pred, score, positive)
  metrics <- compute_binary_metrics(y_test, pred, score, positive)

  end_predict <- Sys.time()

  runtime <- make_runtime_table(method_id, as.numeric(difftime(end_train, start_train, units = "secs")), as.numeric(difftime(end_predict, start_predict, units = "secs")))
  nonzero <- tryCatch(sum(as.vector(coef(fit, s = "lambda.min")) != 0), error = function(e) NA_integer_)

  model_info <- make_model_info(method_id, model_size = nonzero, n_features_used = ncol(x_train), n_relations_used = 0L, notes = paste0("glmnet elastic-net; alpha=0.5; lambda=lambda.min; nonzero=", nonzero))

  result <- list(predictions = predictions, metrics = metrics, model_info = model_info, runtime = runtime, model = fit)
  validate_method_result(result)
  result
}

fit_predict_svm_linear <- function(x_train, y_train, x_test, y_test, config = list()) {
  method_id <- "svm_linear"
  xx <- sanitize_xy_for_classic(x_train, x_test)
  x_train <- xx$x_train
  x_test <- xx$x_test

  start_train <- Sys.time()
  y_train <- factor(as.character(y_train))
  y_test <- factor(as.character(y_test), levels = levels(y_train))
  positive <- if (!is.null(config$positive)) config$positive else levels(y_train)[2]

  train_df <- data.frame(class_label = y_train, as.data.frame(x_train), check.names = TRUE)
  test_df <- as.data.frame(x_test)

  fit <- e1071::svm(
    class_label ~ .,
    data = train_df,
    kernel = "linear",
    cost = 1,
    scale = FALSE,
    probability = FALSE
  )

  end_train <- Sys.time()
  start_predict <- Sys.time()

  pred <- factor(as.character(predict(fit, newdata = test_df)), levels = levels(y_train))
  score <- rep(NA_real_, length(y_test))

  predictions <- make_prediction_table(make_sample_ids(x_test), y_test, pred, score, positive)
  metrics <- compute_binary_metrics(y_test, pred, score, positive)

  end_predict <- Sys.time()

  runtime <- make_runtime_table(method_id, as.numeric(difftime(end_train, start_train, units = "secs")), as.numeric(difftime(end_predict, start_predict, units = "secs")))
  model_info <- make_model_info(method_id, model_size = tryCatch(length(fit$index), error = function(e) NA_integer_), n_features_used = ncol(x_train), n_relations_used = 0L, notes = "e1071 linear SVM; cost=1; no tuning; hard labels only")

  result <- list(predictions = predictions, metrics = metrics, model_info = model_info, runtime = runtime, model = fit)
  validate_method_result(result)
  result
}

fit_predict_knn_euclidean <- function(x_train, y_train, x_test, y_test, config = list()) {
  method_id <- "knn_euclidean"
  xx <- sanitize_xy_for_classic(x_train, x_test)
  x_train <- xx$x_train
  x_test <- xx$x_test

  start_train <- Sys.time()
  y_train <- factor(as.character(y_train))
  y_test <- factor(as.character(y_test), levels = levels(y_train))
  positive <- if (!is.null(config$positive)) config$positive else levels(y_train)[2]
  k <- if (!is.null(config$k)) config$k else 5
  end_train <- Sys.time()

  start_predict <- Sys.time()
  pred <- class::knn(train = x_train, test = x_test, cl = y_train, k = k)
  pred <- factor(as.character(pred), levels = levels(y_train))
  score <- rep(NA_real_, length(y_test))

  predictions <- make_prediction_table(make_sample_ids(x_test), y_test, pred, score, positive)
  metrics <- compute_binary_metrics(y_test, pred, score, positive)
  end_predict <- Sys.time()

  runtime <- make_runtime_table(method_id, as.numeric(difftime(end_train, start_train, units = "secs")), as.numeric(difftime(end_predict, start_predict, units = "secs")))
  model_info <- make_model_info(method_id, model_size = k, n_features_used = ncol(x_train), n_relations_used = 0L, notes = paste0("Euclidean kNN; k=", k, "; train-only scaled features expected"))

  result <- list(predictions = predictions, metrics = metrics, model_info = model_info, runtime = runtime, model = list(k = k))
  validate_method_result(result)
  result
}

fit_predict_rpart_tree <- function(x_train, y_train, x_test, y_test, config = list()) {
  method_id <- "rpart_tree"
  xx <- sanitize_xy_for_classic(x_train, x_test)
  x_train <- xx$x_train
  x_test <- xx$x_test

  start_train <- Sys.time()
  y_train <- factor(as.character(y_train))
  y_test <- factor(as.character(y_test), levels = levels(y_train))
  positive <- if (!is.null(config$positive)) config$positive else levels(y_train)[2]

  train_df <- data.frame(class_label = y_train, as.data.frame(x_train), check.names = TRUE)
  test_df <- as.data.frame(x_test)

  fit <- rpart::rpart(
    class_label ~ .,
    data = train_df,
    method = "class",
    control = rpart::rpart.control(cp = 0.01, minsplit = 20, minbucket = 7, xval = 0)
  )

  end_train <- Sys.time()
  start_predict <- Sys.time()

  prob <- predict(fit, newdata = test_df, type = "prob")
  score <- as.numeric(prob[, positive])
  pred <- factor(ifelse(score >= 0.5, positive, setdiff(levels(y_train), positive)), levels = levels(y_train))

  predictions <- make_prediction_table(make_sample_ids(x_test), y_test, pred, score, positive)
  metrics <- compute_binary_metrics(y_test, pred, score, positive)

  end_predict <- Sys.time()

  runtime <- make_runtime_table(method_id, as.numeric(difftime(end_train, start_train, units = "secs")), as.numeric(difftime(end_predict, start_predict, units = "secs")))
  model_info <- make_model_info(method_id, model_size = nrow(fit$frame), n_features_used = ncol(x_train), n_relations_used = 0L, notes = "rpart CART; cp=0.01; minsplit=20; minbucket=7; no tuning")

  result <- list(predictions = predictions, metrics = metrics, model_info = model_info, runtime = runtime, model = fit)
  validate_method_result(result)
  result
}

fit_predict_ranger_rf <- function(x_train, y_train, x_test, y_test, config = list()) {
  method_id <- "ranger_rf"
  xx <- sanitize_xy_for_classic(x_train, x_test)
  x_train <- xx$x_train
  x_test <- xx$x_test

  start_train <- Sys.time()
  y_train <- factor(as.character(y_train))
  y_test <- factor(as.character(y_test), levels = levels(y_train))
  positive <- if (!is.null(config$positive)) config$positive else levels(y_train)[2]

  train_df <- data.frame(class_label = y_train, as.data.frame(x_train), check.names = TRUE)
  test_df <- as.data.frame(x_test)

  fit <- ranger::ranger(
    class_label ~ .,
    data = train_df,
    probability = TRUE,
    num.trees = 50,
    mtry = max(1, floor(sqrt(ncol(x_train)))),
    min.node.size = 5,
    seed = if (!is.null(config$seed)) config$seed else 123,
    num.threads = 1
  )

  end_train <- Sys.time()
  start_predict <- Sys.time()

  pred_obj <- predict(fit, data = test_df)
  prob <- pred_obj$predictions
  score <- as.numeric(prob[, positive])
  pred <- factor(ifelse(score >= 0.5, positive, setdiff(levels(y_train), positive)), levels = levels(y_train))

  predictions <- make_prediction_table(make_sample_ids(x_test), y_test, pred, score, positive)
  metrics <- compute_binary_metrics(y_test, pred, score, positive)

  end_predict <- Sys.time()

  runtime <- make_runtime_table(method_id, as.numeric(difftime(end_train, start_train, units = "secs")), as.numeric(difftime(end_predict, start_predict, units = "secs")))
  model_info <- make_model_info(method_id, model_size = 25L, n_features_used = ncol(x_train), n_relations_used = 0L, notes = "ranger RF; num.trees=50; mtry=sqrt(p); min.node.size=5; num.threads=1; no tuning")

  result <- list(predictions = predictions, metrics = metrics, model_info = model_info, runtime = runtime, model = fit)
  validate_method_result(result)
  result
}

fit_predict_xgboost_shallow <- function(x_train, y_train, x_test, y_test, config = list()) {
  method_id <- "xgboost_shallow"
  xx <- sanitize_xy_for_classic(x_train, x_test)
  x_train <- xx$x_train
  x_test <- xx$x_test

  start_train <- Sys.time()
  y_train <- factor(as.character(y_train))
  y_test <- factor(as.character(y_test), levels = levels(y_train))
  positive <- if (!is.null(config$positive)) config$positive else levels(y_train)[2]
  y01 <- as.numeric(y_train == positive)

  set.seed(if (!is.null(config$seed)) config$seed else 123)

  dtrain <- xgboost::xgb.DMatrix(data = x_train, label = y01)
  dtest <- xgboost::xgb.DMatrix(data = x_test)

  fit <- xgboost::xgb.train(
    params = list(
      objective = "binary:logistic",
      eval_metric = "logloss",
      max_depth = 2,
      eta = 0.1,
      subsample = 0.8,
      colsample_bytree = 0.8,
      nthread = 1
    ),
    data = dtrain,
    nrounds = 25,
    verbose = 0
  )

  end_train <- Sys.time()
  start_predict <- Sys.time()

  score <- as.numeric(predict(fit, dtest))
  pred <- factor(ifelse(score >= 0.5, positive, setdiff(levels(y_train), positive)), levels = levels(y_train))

  predictions <- make_prediction_table(make_sample_ids(x_test), y_test, pred, score, positive)
  metrics <- compute_binary_metrics(y_test, pred, score, positive)

  end_predict <- Sys.time()

  runtime <- make_runtime_table(method_id, as.numeric(difftime(end_train, start_train, units = "secs")), as.numeric(difftime(end_predict, start_predict, units = "secs")))
  model_info <- make_model_info(method_id, model_size = 25L, n_features_used = ncol(x_train), n_relations_used = 0L, notes = "xgboost shallow; max_depth=2; eta=0.1; nrounds=25; no tuning")

  result <- list(predictions = predictions, metrics = metrics, model_info = model_info, runtime = runtime, model = fit)
  validate_method_result(result)
  result
}
