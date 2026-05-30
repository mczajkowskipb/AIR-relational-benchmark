# Core preprocessing utilities.
#
# Convention:
# - X is samples x features.
# - Feature filtering is fitted on training data only.
# - The returned selected feature list must then be applied to test data.

fit_mad_filter <- function(x_train, n_features = 1000) {
  x_train <- as.matrix(x_train)

  if (is.null(colnames(x_train))) {
    colnames(x_train) <- paste0("feature_", seq_len(ncol(x_train)))
  }

  mad_values <- apply(x_train, 2, stats::mad, na.rm = TRUE)

  mad_values[!is.finite(mad_values)] <- -Inf

  ord <- order(mad_values, decreasing = TRUE, na.last = TRUE)
  n_select <- min(n_features, length(ord))

  selected_idx <- ord[seq_len(n_select)]
  selected_features <- colnames(x_train)[selected_idx]

  data.frame(
    feature = selected_features,
    rank = seq_along(selected_features),
    mad = mad_values[selected_idx],
    stringsAsFactors = FALSE
  )
}

apply_feature_filter <- function(x, selected_features) {
  x <- as.matrix(x)

  missing_features <- setdiff(selected_features, colnames(x))
  if (length(missing_features) > 0) {
    stop(
      "Some selected features are missing in the target matrix: ",
      paste(head(missing_features, 10), collapse = ", ")
    )
  }

  x[, selected_features, drop = FALSE]
}

fit_median_imputer <- function(x_train) {
  x_train <- as.matrix(x_train)

  medians <- apply(x_train, 2, function(z) {
    z <- z[is.finite(z)]
    if (length(z) == 0) {
      return(0)
    }
    stats::median(z, na.rm = TRUE)
  })

  medians
}

apply_median_imputer <- function(x, medians) {
  x <- as.matrix(x)

  missing_features <- setdiff(names(medians), colnames(x))
  if (length(missing_features) > 0) {
    stop(
      "Some imputer features are missing in the target matrix: ",
      paste(head(missing_features, 10), collapse = ", ")
    )
  }

  x <- x[, names(medians), drop = FALSE]

  for (j in seq_len(ncol(x))) {
    bad <- !is.finite(x[, j])
    if (any(bad)) {
      x[bad, j] <- medians[j]
    }
  }

  x
}

fit_standard_scaler <- function(x_train) {
  x_train <- as.matrix(x_train)

  center <- colMeans(x_train, na.rm = TRUE)
  scale <- apply(x_train, 2, stats::sd, na.rm = TRUE)

  center[!is.finite(center)] <- 0
  scale[!is.finite(scale) | scale == 0] <- 1

  list(center = center, scale = scale)
}

apply_standard_scaler <- function(x, scaler) {
  x <- as.matrix(x)

  required_features <- names(scaler$center)
  missing_features <- setdiff(required_features, colnames(x))
  if (length(missing_features) > 0) {
    stop(
      "Some scaler features are missing in the target matrix: ",
      paste(head(missing_features, 10), collapse = ", ")
    )
  }

  x <- x[, required_features, drop = FALSE]

  sweep(
    sweep(x, 2, scaler$center, FUN = "-"),
    2,
    scaler$scale,
    FUN = "/"
  )
}

fit_preprocessing <- function(
  x_train,
  feature_filter = c("mad", "none"),
  n_features = 1000,
  impute = TRUE,
  scale = FALSE
) {
  feature_filter <- match.arg(feature_filter)
  x_train <- as.matrix(x_train)

  if (is.null(colnames(x_train))) {
    colnames(x_train) <- paste0("feature_", seq_len(ncol(x_train)))
  }

  if (feature_filter == "mad") {
    selected_table <- fit_mad_filter(x_train, n_features = n_features)
    selected_features <- selected_table$feature
  } else {
    selected_features <- colnames(x_train)
    selected_table <- data.frame(
      feature = selected_features,
      rank = seq_along(selected_features),
      mad = NA_real_,
      stringsAsFactors = FALSE
    )
  }

  x_selected <- apply_feature_filter(x_train, selected_features)

  imputer <- NULL
  if (isTRUE(impute)) {
    imputer <- fit_median_imputer(x_selected)
    x_selected <- apply_median_imputer(x_selected, imputer)
  }

  scaler <- NULL
  if (isTRUE(scale)) {
    scaler <- fit_standard_scaler(x_selected)
    x_selected <- apply_standard_scaler(x_selected, scaler)
  }

  list(
    selected_features = selected_features,
    selected_table = selected_table,
    imputer = imputer,
    scaler = scaler,
    feature_filter = feature_filter,
    n_features = n_features,
    impute = impute,
    scale = scale
  )
}

apply_preprocessing <- function(x, prep) {
  x <- as.matrix(x)

  x_out <- apply_feature_filter(x, prep$selected_features)

  if (!is.null(prep$imputer)) {
    x_out <- apply_median_imputer(x_out, prep$imputer)
  }

  if (!is.null(prep$scaler)) {
    x_out <- apply_standard_scaler(x_out, prep$scaler)
  }

  x_out
}
