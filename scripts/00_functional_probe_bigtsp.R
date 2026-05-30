cat("=== Functional probe: BigTSP tsp.tree ===\n")

suppressPackageStartupMessages(library(BigTSP))
suppressPackageStartupMessages(library(tree))

dir.create("results/logs", recursive = TRUE, showWarnings = FALSE)
dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)

set.seed(123)

status <- "FAIL"
message <- NA_character_

tryCatch({
  n_per_class <- 25
  n <- 2 * n_per_class
  p <- 20

  # BigTSP::tsp.tree training input: samples x features
  x <- matrix(rnorm(n * p), nrow = n, ncol = p)
  colnames(x) <- paste0("gene_", seq_len(p))
  rownames(x) <- paste0("sample_", seq_len(n))

  y <- factor(rep(c("A", "B"), each = n_per_class))

  # Inject simple pair signal:
  # Class A: gene_1 > gene_2
  # Class B: gene_1 < gene_2
  x[y == "A", 1] <- x[y == "A", 2] + 2
  x[y == "B", 1] <- x[y == "B", 2] - 2

  train_idx <- c(1:20, 26:45)
  test_idx <- setdiff(seq_len(n), train_idx)

  x_train <- x[train_idx, , drop = FALSE]
  x_test <- x[test_idx, , drop = FALSE]
  y_train <- droplevels(y[train_idx])
  y_test <- droplevels(y[test_idx])

  cat("Train dimensions:\n")
  print(dim(x_train))
  cat("Test dimensions:\n")
  print(dim(x_test))
  cat("Train class table:\n")
  print(table(y_train))
  cat("Test class table:\n")
  print(table(y_test))

  cat("Checking S3 predict method:\n")
  print(getS3method("predict", "tsp.tree", optional = TRUE))

  fit <- tsp.tree(
    X = x_train,
    response = y_train,
    control = tree::tree.control(
      nobs = nrow(x_train),
      mincut = 1,
      minsize = 2,
      mindev = 0.001
    )
  )

  cat("Model class:\n")
  print(class(fit))

  cat("Model print:\n")
  print(fit)

  # IMPORTANT:
  # BigTSP::predict.tsp.tree expects newdata with response in column 1,
  # and features from column 2 onward.
  train_newdata <- data.frame(response = y_train, x_train, check.names = FALSE)
  test_newdata  <- data.frame(response = y_test,  x_test,  check.names = FALSE)

  pred_train <- predict(fit, newdata = train_newdata, type = "class")
  pred_test  <- predict(fit, newdata = test_newdata,  type = "class")

  cat("Train predictions:\n")
  print(table(pred_train, y_train))

  cat("Test predictions:\n")
  print(table(pred_test, y_test))

  acc_train <- mean(as.character(pred_train) == as.character(y_train))
  acc_test <- mean(as.character(pred_test) == as.character(y_test))

  cat("Train accuracy:", acc_train, "\n")
  cat("Test accuracy:", acc_test, "\n")

  status <- "PASS_WRAPPER"
  message <- paste0(
    "BigTSP tsp.tree completed; train_acc=",
    round(acc_train, 3),
    "; test_acc=",
    round(acc_test, 3)
  )

}, error = function(e) {
  status <<- "FAIL"
  message <<- conditionMessage(e)
})

res <- data.frame(
  method = "tspdt_bigtsp",
  status = status,
  message = message,
  stringsAsFactors = FALSE
)

print(res)
write.csv(res, "results/runtime/bigtsp_functional_probe.csv", row.names = FALSE)

cat("=== Functional probe finished ===\n")
