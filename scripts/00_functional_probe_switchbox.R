cat("=== Functional probe: switchBox TSP/kTSP using package example data ===\n")

suppressPackageStartupMessages(library(switchBox))

dir.create("results/logs", recursive = TRUE, showWarnings = FALSE)
dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)

status <- "FAIL"
message <- NA_character_

tryCatch({
  data(trainingData)
  data(testingData)

  cat("Objects after loading package data:\n")
  print(ls())

  cat("Training matrix dimensions:\n")
  print(dim(matTraining))
  cat("Testing matrix dimensions:\n")
  print(dim(matTesting))
  cat("Training groups:\n")
  print(table(trainingGroup))
  cat("Testing groups:\n")
  print(table(testingGroup))

  classifier <- SWAP.KTSP.Train(
    matTraining,
    trainingGroup,
    krange = c(3, 5, 7)
  )

  cat("Classifier object:\n")
  print(classifier)
  cat("Classifier structure:\n")
  print(str(classifier))

  pred_train <- SWAP.KTSP.Classify(matTraining, classifier)
  pred_test  <- SWAP.KTSP.Classify(matTesting, classifier)

  cat("Train predictions:\n")
  print(table(pred_train, trainingGroup))

  cat("Test predictions:\n")
  print(table(pred_test, testingGroup))

  acc_train <- mean(as.character(pred_train) == as.character(trainingGroup))
  acc_test  <- mean(as.character(pred_test) == as.character(testingGroup))

  cat("Train accuracy:", acc_train, "\n")
  cat("Test accuracy:", acc_test, "\n")

  status <- "PASS_WRAPPER"
  message <- paste0(
    "switchBox package example completed; train_acc=",
    round(acc_train, 3),
    "; test_acc=",
    round(acc_test, 3)
  )

}, error = function(e) {
  status <<- "FAIL"
  message <<- conditionMessage(e)
})

res <- data.frame(
  method = "switchbox_ktsp",
  status = status,
  message = message,
  stringsAsFactors = FALSE
)

print(res)
write.csv(res, "results/runtime/switchbox_functional_probe.csv", row.names = FALSE)

cat("=== Functional probe finished ===\n")
