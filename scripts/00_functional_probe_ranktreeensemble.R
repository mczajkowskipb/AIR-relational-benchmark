cat("=== Functional probe: ranktreeEnsemble Random Rank Forest ===\n")

suppressPackageStartupMessages(library(ranktreeEnsemble))

dir.create("results/logs", recursive = TRUE, showWarnings = FALSE)
dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)

set.seed(123)

status <- "FAIL"
message <- NA_character_

tryCatch({
  data(tnbc)

  cat("tnbc dimensions:\n")
  print(dim(tnbc))

  cat("tnbc column names tail:\n")
  print(tail(colnames(tnbc)))

  # Use package-documented structure:
  # first 10 expression variables + subtype outcome.
  dat <- tnbc[, c(1:10, 337)]
  dat$subtype <- factor(dat$subtype)

  cat("Class table:\n")
  print(table(dat$subtype))

  train_idx <- 1:150
  test_idx <- 151:200

  train_dat <- dat[train_idx, , drop = FALSE]
  test_x <- dat[test_idx, 1:10, drop = FALSE]
  test_y <- droplevels(dat$subtype[test_idx])

  cat("Train dimensions:\n")
  print(dim(train_dat))
  cat("Test dimensions:\n")
  print(dim(test_x))

  fit <- rforest(
    subtype ~ .,
    data = train_dat,
    ntree = 50,
    seed = 123,
    importance = TRUE
  )

  cat("Model class:\n")
  print(class(fit))

  pred_obj <- predict(fit, test_x)

  cat("Prediction object names:\n")
  print(names(pred_obj))

  pred <- factor(pred_obj$label, levels = levels(dat$subtype))

  cat("Prediction table:\n")
  print(table(pred, test_y))

  acc <- mean(as.character(pred) == as.character(test_y))
  cat("Test accuracy:", acc, "\n")

  imp <- importance(fit)
  cat("Importance object class/dim:\n")
  print(class(imp))
  print(dim(imp))

  rules_ok <- FALSE
  rules_n <- NA_integer_

  rules_obj <- tryCatch({
    extract.rules(fit, subtrees = 3, treedepth = 2)
  }, error = function(e) {
    cat("extract.rules failed:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(rules_obj) && !is.null(rules_obj$rule)) {
    rules_ok <- TRUE
    rules_n <- nrow(rules_obj$rule)
    cat("Extracted rule count:", rules_n, "\n")
    print(head(rules_obj$rule))
  }

  status <- "PASS_WRAPPER"
  message <- paste0(
    "ranktreeEnsemble rforest completed; test_acc=",
    round(acc, 3),
    "; rules_ok=",
    rules_ok,
    "; rules_n=",
    rules_n
  )

}, error = function(e) {
  status <<- "FAIL"
  message <<- conditionMessage(e)
})

res <- data.frame(
  method = "rrf_ranktreeensemble",
  status = status,
  message = message,
  stringsAsFactors = FALSE
)

print(res)
write.csv(res, "results/runtime/ranktreeensemble_functional_probe.csv", row.names = FALSE)

cat("=== Functional probe finished ===\n")
