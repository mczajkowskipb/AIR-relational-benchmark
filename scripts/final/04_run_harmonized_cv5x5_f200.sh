#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

JOBS="${JOBS:-29}"

echo "=== Run harmonized cv5x5 f200 benchmark ==="
echo "Parallel jobs: ${JOBS}"

mkdir -p results/harmonized_cv5x5_f200/logs
mkdir -p results/tspdt_f200_pps/logs

echo
echo "[1] Main harmonized grid"
if [ -f scripts/run_harmonized_cv5x5_f200_parallel.sh ]; then
  bash scripts/run_harmonized_cv5x5_f200_parallel.sh
else
  echo "WARNING: scripts/run_harmonized_cv5x5_f200_parallel.sh not found; skipping main rerun."
fi

echo
echo "[2] TSPDT f200 with increased R protection stack"
JOBS="${JOBS}" bash scripts/final/04_run_tspdt_f200_pps.sh

echo
echo "[3] Collect final summaries"
bash scripts/final/05_collect_final_results.sh

echo "=== full benchmark script finished ==="
