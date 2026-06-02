#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

JOBS="${JOBS:-29}"
PROTOCOL="cv_5x5_tspdt_f200_pps"

mkdir -p results/tspdt_f200_pps/logs

CMD_FILE="results/tspdt_f200_pps/tspdt_f200_pps_commands.txt"
RUN_FILE="results/tspdt_f200_pps/tspdt_f200_pps_run_commands.sh"
JOBLOG="results/tspdt_f200_pps/tspdt_f200_pps_parallel_joblog.tsv"

: > "$CMD_FILE"

for f in data/folds/${PROTOCOL}__*.csv; do
  b="$(basename "$f")"
  dataset="${b#${PROTOCOL}__}"
  dataset="${dataset%.csv}"

  for repeat_id in 1 2 3 4 5; do
    for fold_id in 1 2 3 4 5; do
      echo "Rscript --max-ppsize=500000 scripts/10_run_single_job.R --protocol=${PROTOCOL} --dataset=${dataset} --method=tspdt_bigtsp --repeat=${repeat_id} --fold=${fold_id} --n_features=200" >> "$CMD_FILE"
    done
  done
done

awk '{print $0 " > results/tspdt_f200_pps/logs/tspdt_f200_pps_job_" NR ".log 2>&1"}' "$CMD_FILE" > "$RUN_FILE"

echo "TSPDT f200 pps jobs: $(wc -l < "$CMD_FILE")"
parallel -j "$JOBS" --joblog "$JOBLOG" :::: "$RUN_FILE"
