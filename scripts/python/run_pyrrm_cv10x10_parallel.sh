#!/usr/bin/env bash
set -euo pipefail

cd /opt/2026/AIReview

mkdir -p results/pyrrm_jobs/logs

.venv/bin/python scripts/python/08_make_pyrrm_grid.py

awk '{print $0 " > results/pyrrm_jobs/logs/pyrrm_job_" NR ".log 2>&1"}' \
  results/pyrrm_jobs/cv_10x10_pyrrm_commands.txt > results/pyrrm_jobs/cv_10x10_pyrrm_run_commands.sh

parallel -j 29 --joblog results/pyrrm_jobs/cv_10x10_pyrrm_parallel_joblog.tsv \
  :::: results/pyrrm_jobs/cv_10x10_pyrrm_run_commands.sh
