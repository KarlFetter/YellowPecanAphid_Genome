#!/bin/bash
#SBATCH --job-name=BUSCO_PROT
#SBATCH --partition=ceres
#SBATCH --time=48:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --mem=128G
#SBATCH --mail-type=END,FAIL
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

module load busco5/5.7.1

PROTEINS="/90daydata/tgl_seqdata/aphids/annotation/ypa/funannotate/hemiptera_output/predict_results/Monelliopsis_pecanis_YPA.proteins.fa"
BUSCO_DB="/project/tgl_seqdata/databases/BUSCO/busco_downloads/lineages/insecta_odb10"

busco -f \
  -i "$PROTEINS" \
  -l "$BUSCO_DB" \
  -m protein \
  -c "$SLURM_CPUS_PER_TASK" \
  -o "busco_Hemi" \
  --offline
