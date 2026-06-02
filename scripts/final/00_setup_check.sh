#!/usr/bin/env bash
set -euo pipefail

echo "=== AIR benchmark setup check ==="
echo
echo "[1] Repository:"
pwd
git rev-parse --show-toplevel 2>/dev/null || true
git branch --show-current 2>/dev/null || true

echo
echo "[2] R:"
Rscript --version
Rscript -e 'cat("R version:", R.version.string, "\n")'

echo
echo "[3] Python:"
if [ -x ".venv/bin/python" ]; then
  .venv/bin/python --version
elif command -v python3 >/dev/null 2>&1; then
  python3 --version
elif command -v python >/dev/null 2>&1; then
  python --version
else
  echo "MISSING Python"
fi

echo
echo "[4] Required final result files:"
for f in \
  results/summary/harmonized_cv5x5_f200_complete_overall_summary.csv \
  results/summary/harmonized_cv5x5_f200_complete_dataset_method_summary.csv
do
  if [ -f "$f" ]; then
    echo "OK $f"
  else
    echo "MISSING $f"
  fi
done

echo
echo "[5] Data/folds:"
for d in data/final data/folds data/manifests; do
  if [ -d "$d" ]; then
    echo "OK $d"
  else
    echo "MISSING $d"
  fi
done

echo
echo "[6] Method packages quick check:"
Rscript - << 'RSCRIPT'
pkgs <- c("switchBox", "BigTSP", "ranktreeEnsemble", "glmnet", "e1071", "ranger", "rpart", "xgboost")
for (p in pkgs) {
  ok <- requireNamespace(p, quietly = TRUE)
  cat(sprintf("%-20s %s\n", p, ifelse(ok, "OK", "MISSING")))
}
RSCRIPT

echo "=== setup check finished ==="
