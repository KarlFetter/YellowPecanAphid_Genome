#!/bin/bash
#SBATCH --job-name=ONT_STATS
#SBATCH --partition=ceres
#SBATCH --time=4:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load seqkit

# ============================================================
# ONT PromethION read statistics
# ============================================================
# Runs seqkit stats across all *.fastq.gz files in the
# ONT fastq_pass barcode directory. Reads are NOT concatenated;
# they will be passed directly to hifiasm --ul via comma-
# separated list in 04_assembly/hifiasm_ul/01_hifiasm_ul.sh.
# ============================================================

THREADS=8
ONT_DIR=/project/tgl_seqdata/barcoded_sequences/BMA4_BPA5_YPA6_CaquaR1T6/20260421_1552_P2I-00455-A_PBK06960_e4cde178/fastq_pass/barcode03
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads
PREFIX=ypa_ont
EXPECTED_SIZE=516784515

mkdir -p ${OUTDIR}

# Verify the barcode directory exists and has reads
[[ -d "${ONT_DIR}" ]] || { echo "ERROR: ONT directory not found: ${ONT_DIR}"; exit 1; }

FILE_COUNT=$(ls "${ONT_DIR}"/*.fastq.gz 2>/dev/null | wc -l)
[[ ${FILE_COUNT} -gt 0 ]] || { echo "ERROR: No *.fastq.gz files found in ${ONT_DIR}"; exit 1; }

echo "[$(date)] ONT read directory: ${ONT_DIR}"
echo "[$(date)] Files found: ${FILE_COUNT}"

# ============================================================
# Per-file statistics
# ============================================================
echo "[$(date)] Running per-file seqkit stats..."
seqkit stats -j ${THREADS} -a \
    "${ONT_DIR}"/*.fastq.gz \
    > ${OUTDIR}/${PREFIX}_per_file_stats.txt

echo "[$(date)] Per-file stats written to: ${OUTDIR}/${PREFIX}_per_file_stats.txt"
cat ${OUTDIR}/${PREFIX}_per_file_stats.txt

# ============================================================
# Aggregate statistics across all files
# ============================================================
echo ""
echo "[$(date)] Running aggregate seqkit stats..."

# Aggregate: sum reads and bases from the per-file stats table
TOTAL_SEQS=$(awk 'NR>1 {sum += $4} END {print sum}' ${OUTDIR}/${PREFIX}_per_file_stats.txt)
TOTAL_BASES=$(awk 'NR>1 {sum += $5} END {print sum}' ${OUTDIR}/${PREFIX}_per_file_stats.txt)
TOTAL_GB=$(echo "scale=3; ${TOTAL_BASES} / 1000000000" | bc)

# Genome size estimate for coverage calculation (adjust after genome size estimation)
COVERAGE=$(echo "scale=2; ${TOTAL_BASES} / ${EXPECTED_SIZE}" | bc)

echo "============================================" > ${OUTDIR}/${PREFIX}_summary.txt
echo "ONT Read Summary" >> ${OUTDIR}/${PREFIX}_summary.txt
echo "Species: Monelliopsis pecanis (Yellow pecan aphid)" >> ${OUTDIR}/${PREFIX}_summary.txt
echo "Barcode: barcode03" >> ${OUTDIR}/${PREFIX}_summary.txt
echo "============================================" >> ${OUTDIR}/${PREFIX}_summary.txt
echo "Files processed:      ${FILE_COUNT}" >> ${OUTDIR}/${PREFIX}_summary.txt
echo "Total reads:          ${TOTAL_SEQS}" >> ${OUTDIR}/${PREFIX}_summary.txt
echo "Total bases:          ${TOTAL_BASES}" >> ${OUTDIR}/${PREFIX}_summary.txt
echo "Total Gb:             ${TOTAL_GB}" >> ${OUTDIR}/${PREFIX}_summary.txt
echo "Expected genome size: ${EXPECTED_SIZE} bp" >> ${OUTDIR}/${PREFIX}_summary.txt
echo "Estimated coverage:   ${COVERAGE}x" >> ${OUTDIR}/${PREFIX}_summary.txt
echo "============================================" >> ${OUTDIR}/${PREFIX}_summary.txt

cat ${OUTDIR}/${PREFIX}_summary.txt
echo "[$(date)] Done."

