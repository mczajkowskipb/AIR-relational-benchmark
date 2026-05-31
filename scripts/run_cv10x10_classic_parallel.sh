#!/usr/bin/env bash
set -euo pipefail

cd /opt/2026/AIReview

mkdir -p results/job_grid
mkdir -p results/jobs/logs

Rscript scripts/13_make_classic_job_grid.R

awk '{print $0 " > results/jobs/logs/classic_job_" NR ".log 2>&1"}' \
  results/job_grid/cv_10x10_classic_commands.txt > results/job_grid/cv_10x10_classic_run_commands.sh

parallel -j 29 --joblog results/job_grid/cv_10x10_classic_parallel_joblog.tsv \
  :::: results/job_grid/cv_10x10_classic_run_commands.sh
