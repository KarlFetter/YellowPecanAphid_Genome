#!/bin/bash
#SBATCH --job-name=FUN_HEMIP
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

BASE_DIR="/90daydata/tgl_seqdata/aphids/annotation/ypa/funannotate"
GENOME="/90daydata/tgl_seqdata/aphids/assembly/ypa/10_soft_masked_draft/ypa_primary.fa"
PROT_DB="/project/tgl_seqdata/databases/RefSeq/hemiptera_protein_sets/hemiptera_refseq_N50.faa"
OUT_DIR="${BASE_DIR}/hemiptera_output"

export FUNANNOTATE_DB="/project/tgl_seqdata/databases/funannotate_db"
export AUGUSTUS_CONFIG_PATH="/90daydata/tgl_seqdata/aphids/annotation/ypa/augustus/config"

mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

funannotate predict \
  -i "$GENOME" \
  --protein_evidence "$PROT_DB" \
  -o "$OUT_DIR" \
  --species "Monelliopsis pecanis" \
  --strain "YPA" \
  --busco_db "arthropoda" \
  --cpus "$SLURM_CPUS_PER_TASK"
