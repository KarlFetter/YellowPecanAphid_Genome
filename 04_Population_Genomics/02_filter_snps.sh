#!/bin/bash
#SBATCH --job-name=BCFTOOLS_FILTER_ONLY
#SBATCH --partition=ceres
#SBATCH --time=12:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

module load bcftools

WORK_DIR="/90daydata/tgl_seqdata/aphids/popgen/ypa/01_snps"
RAW_VCF="${WORK_DIR}/ypa_raw_variants.vcf.gz"
FILTERED_VCF="${WORK_DIR}/ypa_DP10_220_biallelic.vcf.gz"

bcftools view --threads "$SLURM_CPUS_PER_TASK" \
  -v snps \
  -m2 -M2 \
  -i 'QUAL >= 30 && INFO/DP >= 10 && INFO/DP <= 220 && sum(DP4) <= 220' \
  -Oz -o "$FILTERED_VCF" \
  "$RAW_VCF"

bcftools index "$FILTERED_VCF"
