#!/bin/bash
#SBATCH --job-name=YPA_TE_WINDOWS
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

WORK_DIR="/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/data"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENOME="/90daydata/tgl_seqdata/aphids/assembly/ypa/10_soft_masked_draft/ypa_primary_top6.fa"
REPEAT_TSV="${WORK_DIR}/repeat_locations_types_k2_Complete_and_Fragmentary.tsv"
VCF="/90daydata/tgl_seqdata/aphids/popgen/ypa/01_snps/ypa_DP10_220_biallelic_top6.vcf.gz"

mkdir -p "${WORK_DIR}"
[[ -s "${GENOME}" ]] || { echo "Missing genome: ${GENOME}" >&2; exit 1; }
[[ -s "${REPEAT_TSV}" ]] || { echo "Missing repeat TSV: ${REPEAT_TSV}" >&2; exit 1; }
[[ -s "${VCF}" ]] || { echo "Missing VCF: ${VCF}" >&2; exit 1; }

if [[ ! -s "${GENOME}.fai" ]]; then
    command -v samtools >/dev/null || { echo "samtools is required" >&2; exit 1; }
    samtools faidx "${GENOME}"
fi

python3 "${SCRIPT_DIR}/make_windows.py" \
    --genome "${GENOME}" \
    --fai "${GENOME}.fai" \
    --repeats "${REPEAT_TSV}" \
    --vcf "${VCF}" \
    --outdir "${WORK_DIR}" \
    --seed 20260902

echo "Window construction completed: ${WORK_DIR}"