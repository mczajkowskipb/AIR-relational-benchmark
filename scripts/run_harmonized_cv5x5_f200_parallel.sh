#!/usr/bin/env bash
set -euo pipefail

cd /opt/2026/AIReview

mkdir -p results/harmonized_cv5x5_f200/logs

.venv/bin/python scripts/python/20_make_cv5x5_folds.py
.venv/bin/python scripts/python/21_make_harmonized_cv5x5_f200_grid.py

awk '{print $0 " > results/harmonized_cv5x5_f200/logs/job_" NR ".log 2>&1"}' \
  results/harmonized_cv5x5_f200/cv_5x5_f200_commands.txt > results/harmonized_cv5x5_f200/cv_5x5_f200_run_commands.sh

parallel -j 29 --joblog results/harmonized_cv5x5_f200/cv_5x5_f200_parallel_joblog.tsv \
  :::: results/harmonized_cv5x5_f200/cv_5x5_f200_run_commands.sh
