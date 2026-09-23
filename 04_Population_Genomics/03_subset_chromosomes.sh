#!/bin/bash
#SBATCH --job-name=VCF_SUBSET_6
#SBATCH --partition=ceres
#SBATCH --time=02:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

module load bcftools

WORK_DIR="/90daydata/tgl_seqdata/aphids/popgen/ypa/01_snps"
INPUT_VCF="${WORK_DIR}/ypa_DP10_220_biallelic.vcf.gz"
OUTPUT_VCF="${WORK_DIR}/ypa_DP10_220_biallelic_top6.vcf.gz"
CHROMOSOMES="ptg000001l_1,ptg000004l_1,ptg000003l_1,ptg000002l_1,ptg000005l_1,ptg000006l_1"

bcftools view --threads "$SLURM_CPUS_PER_TASK" \
  -r "$CHROMOSOMES" \
  -Oz -o "$OUTPUT_VCF" \
  "$INPUT_VCF"

bcftools index "$OUTPUT_VCF"
