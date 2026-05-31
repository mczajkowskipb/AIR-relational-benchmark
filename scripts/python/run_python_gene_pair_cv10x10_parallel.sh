#!/usr/bin/env bash
set -euo pipefail

cd /opt/2026/AIReview

mkdir -p results/python_jobs/logs

.venv/bin/python scripts/python/04_make_python_gene_pair_grid.py

awk '{print $0 " > results/python_jobs/logs/python_job_" NR ".log 2>&1"}' \
  results/python_jobs/cv_10x10_python_gene_pair_commands.txt > results/python_jobs/cv_10x10_python_gene_pair_run_commands.sh

parallel -j 29 --joblog results/python_jobs/cv_10x10_python_gene_pair_parallel_joblog.tsv \
  :::: results/python_jobs/cv_10x10_python_gene_pair_run_commands.sh
