#!/bin/bash
#SBATCH --job-name=YPA_KIMURA_ALIGN
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --mem=16G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

WORK_DIR="/90daydata/tgl_seqdata/aphids/repeats/ypa/04b_RepeatAge"
ALIGN_FILE="/90daydata/tgl_seqdata/aphids/repeats/ypa/03c_RepeatMasker_Top6/ypa_primary_top6.fa.align"

mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

python 00_extract_kimura_align.py \
    --align "${ALIGN_FILE}" \
    --out "${WORK_DIR}/repeat_ages_kimura.tsv"

echo "Kimura extraction completed: ${WORK_DIR}/repeat_ages_kimura.tsv"