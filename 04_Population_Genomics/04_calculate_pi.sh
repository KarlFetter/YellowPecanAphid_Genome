#!/bin/bash
#SBATCH --job-name=PI_YPA
#SBATCH --partition=ceres
#SBATCH --time=24:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

module load vcftools

INPUT_VCF="/90daydata/tgl_seqdata/aphids/popgen/ypa/01_snps/ypa_DP10_220_biallelic_top6.vcf.gz"
OUT_DIR="/90daydata/tgl_seqdata/aphids/popgen/ypa/03_genetic_stats/local_10kb"

mkdir -p "$OUT_DIR"

vcftools --gzvcf "$INPUT_VCF" \
  --window-pi 10000 \
  --window-pi-step 10000 \
  --out "${OUT_DIR}/pi_10kb"

vcftools --gzvcf "$INPUT_VCF" \
  --window-pi 10000 \
  --window-pi-step 2000 \
  --out "${OUT_DIR}/pi_10kb_sliding_window"
