#!/usr/bin/env bash
set -euo pipefail

mkdir -p results/logs

{
  echo "=== DATE ==="
  date

  echo
  echo "=== HOST ==="
  hostname
  uname -a

  echo
  echo "=== CPU / MEMORY ==="
  nproc || true
  free -h || true

  echo
  echo "=== R ==="
  which R || true
  R --version || true
  which Rscript || true
  Rscript --version || true

  echo
  echo "=== R LIB PATHS ==="
  Rscript -e 'print(.libPaths())' || true
  Rscript -e 'print(R.version.string); print(R.home())' || true

  echo
  echo "=== PYTHON ==="
  which python || true
  python --version || true
  which python3 || true
  python3 --version || true
  which pip || true
  pip --version || true
  which pip3 || true
  pip3 --version || true

  echo
  echo "=== CONDA / MAMBA / MICROMAMBA ==="
  which conda || true
  conda --version || true
  which mamba || true
  mamba --version || true
  which micromamba || true
  micromamba --version || true

  echo
  echo "=== COMPILERS ==="
  which gcc || true
  gcc --version | head -5 || true
  which g++ || true
  g++ --version | head -5 || true
  which make || true
  make --version | head -3 || true

  echo
  echo "=== CUDA ==="
  which nvcc || true
  nvcc --version || true
  nvidia-smi || true

  echo
  echo "=== GIT ==="
  git --version || true
  git remote -v || true
  git status --short || true

} 2>&1 | tee results/logs/00_probe_environment.log
