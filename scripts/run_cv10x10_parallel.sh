#!/usr/bin/env bash
set -euo pipefail

cd /opt/2026/AIReview

mkdir -p results/job_grid
mkdir -p results/jobs/logs

if [ ! -f results/job_grid/cv_10x10_commands.txt ]; then
  Rscript scripts/11_make_job_grid.R
fi

awk '{print $0 " > results/jobs/logs/job_" NR ".log 2>&1"}' \
  results/job_grid/cv_10x10_commands.txt > results/job_grid/cv_10x10_run_commands.sh

parallel -j 29 --joblog results/job_grid/cv_10x10_parallel_joblog.tsv \
  :::: results/job_grid/cv_10x10_run_commands.sh
