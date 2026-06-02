#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

echo "=== Collect final AIR benchmark results ==="
PYTHON_BIN="python"
if [ -x ".venv/bin/python" ]; then
  PYTHON_BIN=".venv/bin/python"
fi

if [ ! -f scripts/python/25_collect_tspdt_f200_pps_and_complete_harmonized.py ]; then
  echo "ERROR: collector script not found: scripts/python/25_collect_tspdt_f200_pps_and_complete_harmonized.py"
  exit 1
fi

mkdir -p results/summary
"$PYTHON_BIN" scripts/python/25_collect_tspdt_f200_pps_and_complete_harmonized.py \
  2>&1 | tee results/summary/25_collect_tspdt_f200_pps_and_complete_harmonized.log

echo "Main final summaries:"
ls -lh results/summary/harmonized_cv5x5_f200_complete_* || true
