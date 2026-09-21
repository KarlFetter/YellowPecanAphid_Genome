#!/bin/bash
#SBATCH --job-name=YPA_TE_PIXY
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --mem=4G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate pixy

WORK_DIR="/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/data"
VCF="/90daydata/tgl_seqdata/aphids/popgen/ypa/01_snps/ypa_DP10_220_biallelic_top6.vcf.gz"
POPULATIONS="${WORK_DIR}/pixy_populations.tsv"
THREADS="${SLURM_CPUS_PER_TASK:-1}"

command -v pixy >/dev/null || { echo "pixy is required" >&2; exit 1; }
[[ -s "${VCF}" && -s "${VCF}.tbi" ]] || { echo "VCF or VCF index is missing" >&2; exit 1; }
[[ -s "${POPULATIONS}" ]] || { echo "Create ${POPULATIONS} with sample and population columns before running" >&2; exit 1; }

cd "${WORK_DIR}"
for spec in \
  "te_genomic.bed te_genomic_pi" \
  "left_flank_5kb.bed left_flank_5kb_pi" \
  "right_flank_5kb.bed right_flank_5kb_pi" \
  "non_TE_5kb_windows.bed non_TE_5kb_pi" \
  "non_TE_10kb_windows.bed non_TE_10kb_pi"; do
    read -r BED PREFIX <<< "${spec}"
    pixy --stats pi --vcf "${VCF}" --populations "${POPULATIONS}" \
      --bed_file "${BED}" --output_prefix "${PREFIX}" --n_cores "${THREADS}"
done

echo "pixy calculations completed; inspect pixy output files before merging metadata"