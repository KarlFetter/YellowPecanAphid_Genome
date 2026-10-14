#!/bin/bash
#SBATCH --job-name=BCFTOOLS_VARIANT_CALLING
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=128G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

# Load modules
module load samtools
module load bcftools

# Set inputs
REF_GENOME="/90daydata/tgl_seqdata/aphids/assembly/ypa/08_final_draft_assembly/ypa_primary.cleaned.fa"
INPUT_BAM="/90daydata/tgl_seqdata/aphids/assembly/ypa/09_coverage/primary/ypa_primary_hifi.sorted.bam"
WORK_DIR="/90daydata/tgl_seqdata/aphids/popgen/ypa/01_snps"
RAW_VCF="${WORK_DIR}/ypa_raw_variants.vcf.gz"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Create index if it's missing
if [[ ! -f "${REF_GENOME}.fai" ]]; then
  samtools faidx "$REF_GENOME"
fi

if [[ ! -f "${INPUT_BAM}.bai" ]]; then
  samtools index -@ "$SLURM_CPUS_PER_TASK" "$INPUT_BAM"
fi

# Call variants with bcftools
bcftools mpileup --threads "$SLURM_CPUS_PER_TASK" \
  -f "$REF_GENOME" \
  -e 1 -o 20 \
  -q 20 -Q 20 \
  -Ob -o raw_pileup.bcf "$INPUT_BAM"

bcftools call --threads "$SLURM_CPUS_PER_TASK" \
  -m -v \
  -Oz -o "$RAW_VCF" raw_pileup.bcf

bcftools index "$RAW_VCF"
rm -f raw_pileup.bcf
