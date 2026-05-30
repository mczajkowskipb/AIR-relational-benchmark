cat("=== Functional probe: majority wrapper ===\n")

source("R/core/metrics.R")
source("R/core/model_interface.R")
source("R/methods/method_majority.R")

set.seed(123)

x_train <- matrix(rnorm(20 * 10), nrow = 20, ncol = 10)
x_test  <- matrix(rnorm(8 * 10), nrow = 8, ncol = 10)

rownames(x_train) <- paste0("train_", seq_len(nrow(x_train)))
rownames(x_test)  <- paste0("test_", seq_len(nrow(x_test)))
colnames(x_train) <- paste0("gene_", seq_len(ncol(x_train)))
colnames(x_test)  <- paste0("gene_", seq_len(ncol(x_test)))

y_train <- factor(c(rep("A", 15), rep("B", 5)))
y_test  <- factor(c("A", "A", "A", "B", "B", "B", "B", "A"), levels = levels(y_train))

res <- fit_predict_majority(
  x_train = x_train,
  y_train = y_train,
  x_test = x_test,
  y_test = y_test,
  config = list(positive = "B")
)

print(res$predictions)
print(res$metrics)
print(res$model_info)
print(res$runtime)

stopifnot(all(res$predictions$pred == "A"))
stopifnot(res$model_info$model_size == 1)
stopifnot(res$model_info$n_features_used == 0)
stopifnot(res$model_info$n_relations_used == 0)

dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)
write.csv(res$predictions, "results/runtime/majority_probe_predictions.csv", row.names = FALSE)
write.csv(res$metrics, "results/runtime/majority_probe_metrics.csv", row.names = FALSE)
write.csv(res$model_info, "results/runtime/majority_probe_model_info.csv", row.names = FALSE)
write.csv(res$runtime, "results/runtime/majority_probe_runtime.csv", row.names = FALSE)

cat("=== Majority wrapper probe passed ===\n")
