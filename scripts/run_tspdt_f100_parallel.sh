#!/usr/bin/env bash
set -euo pipefail

cd /opt/2026/AIReview

mkdir -p results/tspdt_f100/logs

Rscript scripts/23_make_tspdt_f100_grid.R

awk '{print $0 " > results/tspdt_f100/logs/tspdt_f100_job_" NR ".log 2>&1"}' \
  results/tspdt_f100/tspdt_f100_commands.txt > results/tspdt_f100/tspdt_f100_run_commands.sh

parallel -j 29 --joblog results/tspdt_f100/tspdt_f100_parallel_joblog.tsv \
  :::: results/tspdt_f100/tspdt_f100_run_commands.sh
