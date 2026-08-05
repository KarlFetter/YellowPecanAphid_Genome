#!/bin/bash
#SBATCH --job-name=BLOBT_MAPREADS
#SBATCH --partition=ceres
#SBATCH --time=24:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load minimap2
module load samtools

set -euo pipefail

# ============================================================
# BlobToolKit — Step 1: Map HiFi reads for per-contig coverage
# Species: Yellow pecan aphid (Monellia caryella)
# ============================================================
# Maps HiFi reads back to the scaffolded assembly using
# minimap2 in map-hifi mode, then sorts and indexes the BAM.
# The BAM provides per-contig coverage depth, which is one of
# the three signals BlobToolKit uses to identify contaminants
# (coverage, GC content, taxonomy).
#
# Contaminant contigs often have anomalous coverage:
#   - Bacterial endosymbionts (e.g. Buchnera aphidicola) may
#     appear at very high coverage relative to nuclear contigs
#   - Foreign contigs from extraction may appear at very low
#     or near-zero coverage
#
# Input:
#   purged.fa.scaffolds.fa — scaffolded primary assembly
#   ypa_hifi_clean.fastq.gz — centrifuge-filtered HiFi reads
#
# Output:
#   coverage.bam      — sorted BAM for BlobToolKit
#   coverage.bam.bai  — BAM index
#
# Run order:
#   01_map_reads.sh       <-- this script
#   02_diamond_nr.sh
#   03_blobtools_create.sh
#   04_blobtools_filter.sh  (run after visual inspection)
# ============================================================

THREADS=32
ASSEMBLY=/90daydata/tgl_seqdata/aphids/assembly/ypa/06_scaffolding/samba_hifiasm_ul/primary/purged.fa.scaffolds.fa
HIFI_READS=/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_hifi.fastq.gz
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/08_contam_filter/blobtoolkit/hifiasm_ul/primary

mkdir -p "${OUTDIR}"

# Verify inputs exist
[[ -f "${ASSEMBLY}"   ]] || { echo "ERROR: Assembly not found: ${ASSEMBLY}";   exit 1; }
[[ -f "${HIFI_READS}" ]] || { echo "ERROR: HiFi reads not found: ${HIFI_READS}"; exit 1; }

echo "[$(date)] Mapping HiFi reads for BlobToolKit coverage"
echo "  Assembly : ${ASSEMBLY}"
echo "  Reads    : ${HIFI_READS}"
echo "  Output   : ${OUTDIR}/coverage.bam"

minimap2 \
    -ax map-hifi \
    -t ${THREADS} \
    "${ASSEMBLY}" \
    "${HIFI_READS}" \
    | samtools sort \
        -@ ${THREADS} \
        -m 4G \
        -o "${OUTDIR}/coverage.bam"

samtools index "${OUTDIR}/coverage.bam"

echo ""
echo "[$(date)] Alignment statistics:"
samtools flagstat "${OUTDIR}/coverage.bam"

echo ""
echo "[$(date)] Step 1 complete"
echo "  BAM   : ${OUTDIR}/coverage.bam"
echo "  Index : ${OUTDIR}/coverage.bam.bai"
echo "  Next  : run 02_diamond_nr.sh"

