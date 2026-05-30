cat("=== Functional probe: preprocessing ===\n")

source("R/core/preprocessing.R")

set.seed(123)

n_train <- 20
n_test <- 8
p <- 50

x_train <- matrix(rnorm(n_train * p), nrow = n_train, ncol = p)
x_test <- matrix(rnorm(n_test * p), nrow = n_test, ncol = p)

colnames(x_train) <- paste0("gene_", seq_len(p))
colnames(x_test) <- paste0("gene_", seq_len(p))

# Make first features highly variable in TRAIN only.
x_train[, 1] <- rnorm(n_train, sd = 20)
x_train[, 2] <- rnorm(n_train, sd = 15)
x_train[, 3] <- rnorm(n_train, sd = 10)

# Add some missing / infinite values.
x_train[1, 4] <- NA
x_train[2, 5] <- Inf
x_test[1, 4] <- NA
x_test[2, 5] <- -Inf

prep <- fit_preprocessing(
  x_train,
  feature_filter = "mad",
  n_features = 10,
  impute = TRUE,
  scale = TRUE
)

x_train_p <- apply_preprocessing(x_train, prep)
x_test_p <- apply_preprocessing(x_test, prep)

cat("Selected features:\n")
print(prep$selected_table)

cat("Processed train dimensions:\n")
print(dim(x_train_p))

cat("Processed test dimensions:\n")
print(dim(x_test_p))

stopifnot(ncol(x_train_p) == 10)
stopifnot(ncol(x_test_p) == 10)
stopifnot(identical(colnames(x_train_p), colnames(x_test_p)))
stopifnot(all(is.finite(x_train_p)))
stopifnot(all(is.finite(x_test_p)))

# Check that MAD selection used train data and selected the deliberately variable features.
stopifnot("gene_1" %in% prep$selected_features)
stopifnot("gene_2" %in% prep$selected_features)
stopifnot("gene_3" %in% prep$selected_features)

res <- data.frame(
  component = "preprocessing",
  status = "PASS",
  n_train = nrow(x_train_p),
  n_test = nrow(x_test_p),
  n_features = ncol(x_train_p),
  selected_features = paste(prep$selected_features, collapse = ";"),
  stringsAsFactors = FALSE
)

print(res)

dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)
write.csv(res, "results/runtime/preprocessing_functional_probe.csv", row.names = FALSE)

cat("=== Preprocessing probe passed ===\n")
