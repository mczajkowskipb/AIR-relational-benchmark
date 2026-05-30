cat("=== Functional probe: metrics ===\n")

source("R/core/metrics.R")

truth <- factor(c("A", "A", "B", "B", "B", "A"))
pred  <- factor(c("A", "B", "B", "B", "A", "A"), levels = levels(truth))
score <- c(0.1, 0.6, 0.9, 0.8, 0.4, 0.2)

res <- compute_binary_metrics(
  truth = truth,
  pred = pred,
  score = score,
  positive = "B"
)

print(res)

dir.create("results/runtime", recursive = TRUE, showWarnings = FALSE)
write.csv(res, "results/runtime/metrics_functional_probe.csv", row.names = FALSE)

stopifnot(abs(res$accuracy - (4 / 6)) < 1e-12)
stopifnot(res$tp == 2)
stopifnot(res$tn == 2)
stopifnot(res$fp == 1)
stopifnot(res$fn == 1)

cat("=== Metrics probe passed ===\n")
