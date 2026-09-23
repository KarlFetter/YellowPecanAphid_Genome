#!/bin/bash
#SBATCH --job-name=FUNC_HEMIP_ANN
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 24
#SBATCH --mem=128G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

module load funannotate/1.8.16

BASE_DIR="/90daydata/tgl_seqdata/aphids/annotation/ypa/fun_functional"
PREDICT_DIR="/90daydata/tgl_seqdata/aphids/annotation/ypa/funannotate/hemiptera_output"
OUT_DIR="${BASE_DIR}/fun_runHemi"

export FUNANNOTATE_DB="/project/tgl_seqdata/databases/funannotate_db"
export AUGUSTUS_CONFIG_PATH="/90daydata/tgl_seqdata/aphids/annotation/ypa/augustus/config"

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

funannotate annotate \
  -i "$PREDICT_DIR" \
  -o "$OUT_DIR" \
  --species "Monelliopsis pecanis" \
  --strain "YPA" \
  --cpus "$SLURM_CPUS_PER_TASK"
