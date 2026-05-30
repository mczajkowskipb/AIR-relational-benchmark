# Common method interface utilities.
#
# Each method wrapper should return a list with:
# - predictions: per-sample predictions
# - metrics: per-fold metrics
# - model_info: model size / method-specific metadata
# - runtime: train and predict time
#
# Convention:
# - X matrices are samples x features.
# - truth and pred are class labels.
# - score should be a numeric score for the positive class, if available.
# - if probabilities are unavailable, score can be NA.

make_sample_ids <- function(x, prefix = "sample") {
  if (!is.null(rownames(x))) {
    return(rownames(x))
  }
  paste0(prefix, "_", seq_len(nrow(x)))
}

make_prediction_table <- function(
  sample_id,
  truth,
  pred,
  score = NULL,
  positive = NULL
) {
  truth <- factor(truth)
  pred <- factor(pred, levels = levels(truth))

  if (is.null(score)) {
    score <- rep(NA_real_, length(truth))
  }

  if (is.null(positive)) {
    if (length(levels(truth)) != 2) {
      positive <- NA_character_
    } else {
      positive <- levels(truth)[2]
    }
  }

  data.frame(
    sample_id = sample_id,
    truth = as.character(truth),
    pred = as.character(pred),
    score = as.numeric(score),
    positive = positive,
    stringsAsFactors = FALSE
  )
}

make_runtime_table <- function(
  method_id,
  train_seconds,
  predict_seconds,
  total_seconds = train_seconds + predict_seconds
) {
  data.frame(
    method_id = method_id,
    train_seconds = as.numeric(train_seconds),
    predict_seconds = as.numeric(predict_seconds),
    total_seconds = as.numeric(total_seconds),
    stringsAsFactors = FALSE
  )
}

make_model_info <- function(
  method_id,
  model_size = NA_integer_,
  n_features_used = NA_integer_,
  n_relations_used = NA_integer_,
  notes = NA_character_
) {
  data.frame(
    method_id = method_id,
    model_size = model_size,
    n_features_used = n_features_used,
    n_relations_used = n_relations_used,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

validate_method_result <- function(result) {
  required <- c("predictions", "metrics", "model_info", "runtime")
  missing <- setdiff(required, names(result))

  if (length(missing) > 0) {
    stop("Method result is missing required fields: ", paste(missing, collapse = ", "))
  }

  pred_required <- c("sample_id", "truth", "pred", "score", "positive")
  missing_pred <- setdiff(pred_required, colnames(result$predictions))

  if (length(missing_pred) > 0) {
    stop("Prediction table is missing required columns: ", paste(missing_pred, collapse = ", "))
  }

  TRUE
}
