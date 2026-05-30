compute_binary_metrics <- function(truth, pred, score = NULL, positive = NULL) {
  truth <- factor(truth)
  pred <- factor(pred, levels = levels(truth))

  if (length(levels(truth)) != 2) {
    stop("compute_binary_metrics currently supports exactly two classes.")
  }

  if (is.null(positive)) {
    positive <- levels(truth)[2]
  }

  negative <- setdiff(levels(truth), positive)
  if (length(negative) != 1) {
    stop("Could not determine negative class.")
  }

  truth_pos <- truth == positive
  pred_pos <- pred == positive

  tp <- sum(truth_pos & pred_pos, na.rm = TRUE)
  tn <- sum(!truth_pos & !pred_pos, na.rm = TRUE)
  fp <- sum(!truth_pos & pred_pos, na.rm = TRUE)
  fn <- sum(truth_pos & !pred_pos, na.rm = TRUE)

  accuracy <- mean(truth == pred, na.rm = TRUE)

  sensitivity <- ifelse((tp + fn) > 0, tp / (tp + fn), NA_real_)
  specificity <- ifelse((tn + fp) > 0, tn / (tn + fp), NA_real_)
  balanced_accuracy <- mean(c(sensitivity, specificity), na.rm = TRUE)

  precision_pos <- ifelse((tp + fp) > 0, tp / (tp + fp), NA_real_)
  recall_pos <- sensitivity
  f1_pos <- ifelse(
    is.na(precision_pos) || is.na(recall_pos) || (precision_pos + recall_pos) == 0,
    NA_real_,
    2 * precision_pos * recall_pos / (precision_pos + recall_pos)
  )

  precision_neg <- ifelse((tn + fn) > 0, tn / (tn + fn), NA_real_)
  recall_neg <- specificity
  f1_neg <- ifelse(
    is.na(precision_neg) || is.na(recall_neg) || (precision_neg + recall_neg) == 0,
    NA_real_,
    2 * precision_neg * recall_neg / (precision_neg + recall_neg)
  )

  macro_f1 <- mean(c(f1_pos, f1_neg), na.rm = TRUE)

  denom <- sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn))
  mcc <- ifelse(denom > 0, ((tp * tn) - (fp * fn)) / denom, NA_real_)

  auc <- NA_real_
  brier <- NA_real_
  logloss <- NA_real_

  if (!is.null(score)) {
    score <- as.numeric(score)

    if (requireNamespace("pROC", quietly = TRUE)) {
      auc <- tryCatch({
        as.numeric(pROC::auc(
          response = truth,
          predictor = score,
          levels = c(negative, positive),
          direction = "<",
          quiet = TRUE
        ))
      }, error = function(e) NA_real_)
    }

    if (all(score >= 0 & score <= 1, na.rm = TRUE)) {
      y01 <- as.numeric(truth == positive)
      eps <- 1e-15
      score_clip <- pmin(pmax(score, eps), 1 - eps)

      brier <- mean((score_clip - y01)^2, na.rm = TRUE)
      logloss <- -mean(
        y01 * log(score_clip) + (1 - y01) * log(1 - score_clip),
        na.rm = TRUE
      )
    }
  }

  data.frame(
    n = length(truth),
    positive = positive,
    negative = negative,
    accuracy = accuracy,
    balanced_accuracy = balanced_accuracy,
    macro_f1 = macro_f1,
    mcc = mcc,
    sensitivity = sensitivity,
    specificity = specificity,
    precision_pos = precision_pos,
    recall_pos = recall_pos,
    f1_pos = f1_pos,
    precision_neg = precision_neg,
    recall_neg = recall_neg,
    f1_neg = f1_neg,
    auc = auc,
    brier = brier,
    logloss = logloss,
    tp = tp,
    tn = tn,
    fp = fp,
    fn = fn,
    stringsAsFactors = FALSE
  )
}
