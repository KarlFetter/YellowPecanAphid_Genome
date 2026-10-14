#!/bin/bash
#SBATCH --job-name=PURGEDUPS_PIPELINE
#SBATCH --partition=ceres
#SBATCH --time=48:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load minimap2
module load purge_dups
module load seqkit

# ============================================================
# purge_dups — Full pipeline (Steps 1–3)
#
# Step 1 — Align HiFi reads to primary assembly (minimap2)
# Step 2 — Coverage stats, cutoffs, and split self-alignment
#           (pbcstat, calcuts, split_fa, minimap2)
# Step 3 — Purge haplotigs and extract sequences
#           (purge_dups, get_seqs, seqkit stats)
#
# SLURM output:
#   %x_%j.out  — combined stdout for all three steps
#   %x_%j.err  — combined stderr for all three steps
#
# Outputs written to OUTDIR:
#   reads_to_assembly.paf.gz   — HiFi-to-assembly alignments
#   PB.base.cov / PB.stat      — per-base and per-read coverage
#   cutoffs                    — coverage thresholds
#   assembly.split.fa          — assembly split at N-gaps
#   assembly.split.self.paf.gz — self-alignment of split assembly
#   dups.bed                   — classified duplicated regions
#   purged.fa                  — purged primary assembly  ← use this
#   hap.fa                     — haplotigs removed from primary
# ============================================================

set -euo pipefail

# ── Input paths ──────────────────────────────────
THREADS=32
ASSEMBLY=/90daydata/tgl_seqdata/aphids/assembly/ypa/04_assembly/hifiasm/ypa.bp.hap1.p_ctg.fa.gz
READS=/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_hifi.fastq.gz
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/05_purge_haplotigs/hifiasm/hap1
# ────────────────────────────────────────────────────────────

mkdir -p "${OUTDIR}"
cd "${OUTDIR}"

echo "============================================================"
echo " purge_dups pipeline — $(date)"
echo " Assembly : ${ASSEMBLY}"
echo " Reads    : ${READS}"
echo " Output   : ${OUTDIR}"
echo "============================================================"
echo ""

# ============================================================
# STEP 1 — Align HiFi reads to primary assembly
# ============================================================
# minimap2 maps each HiFi read to the assembly and streams
# the output as a gzipped PAF for pbcstat in Step 2.
# ============================================================

echo "------------------------------------------------------------"
echo " STEP 1: HiFi read alignment (minimap2 -xmap-hifi)"
echo "------------------------------------------------------------"
echo "[$(date)] Starting minimap2 alignment"

minimap2 \
    -xmap-hifi \
    -t "${THREADS}" \
    "${ASSEMBLY}" \
    "${READS}" \
    | gzip -c > "${OUTDIR}/reads_to_assembly.paf.gz"

echo "[$(date)] Step 1 complete — output: reads_to_assembly.paf.gz"
echo ""

# ============================================================
# STEP 2 — Coverage statistics, cutoffs, and self-alignment
# ============================================================
# pbcstat  — computes per-base (PB.base.cov) and per-read
#            (PB.stat) coverage from the PAF file
# calcuts  — derives low/mid/high coverage thresholds
# split_fa — splits assembly at N-gaps so self-alignment
#            does not span gap regions
# minimap2 — self-alignment in asm5+DP mode to detect
#            overlapping duplicated contig pairs
# ============================================================

echo "------------------------------------------------------------"
echo " STEP 2: Coverage histogram, cutoffs, and self-alignment"
echo "------------------------------------------------------------"

# --- 2a. Build coverage statistics from read alignments -----
echo "[$(date)] Running pbcstat"
pbcstat "${OUTDIR}/reads_to_assembly.paf.gz"
# Outputs: PB.base.cov  PB.stat

# --- 2b. Calculate coverage cutoffs -------------------------
echo "[$(date)] Running calcuts"
calcuts PB.stat > cutoffs 2> calcuts.log

echo "[$(date)] Coverage cutoffs:"
cat cutoffs

# --- 2c. Split assembly at N-gaps for self-alignment --------
echo "[$(date)] Splitting assembly at N-gaps (split_fa)"
split_fa "${ASSEMBLY}" > "${OUTDIR}/assembly.split.fa"

# --- 2d. Self-alignment of the split assembly ---------------
echo "[$(date)] Running self-alignment (minimap2 -xasm5 -DP)"
minimap2 \
    -xasm5 \
    -DP \
    -t "${THREADS}" \
    "${OUTDIR}/assembly.split.fa" \
    "${OUTDIR}/assembly.split.fa" \
    | gzip -c > "${OUTDIR}/assembly.split.self.paf.gz"

echo "[$(date)] Step 2 complete — output: assembly.split.self.paf.gz"
echo ""

# ============================================================
# STEP 3 — Purge haplotigs and extract sequences
# ============================================================
# purge_dups — classifies each contig region using coverage
#              thresholds + self-alignment overlaps, writing
#              a BED of duplicated regions
# get_seqs   — splits the primary assembly into purged.fa
#              (primary) and hap.fa (haplotigs)
# seqkit     — reports quick QC stats on both output FASTAs
# ============================================================

echo "------------------------------------------------------------"
echo " STEP 3: Purge haplotigs and extract sequences"
echo "------------------------------------------------------------"

# --- 3a. Identify and classify duplicated regions -----------
echo "[$(date)] Running purge_dups"
purge_dups \
    -2 \
    -T cutoffs \
    -c PB.base.cov \
    "${OUTDIR}/assembly.split.self.paf.gz" \
    > dups.bed \
    2> purge_dups.log

echo "[$(date)] Duplicated regions written to dups.bed"
echo "  Total regions classified: $(wc -l < dups.bed)"

# --- 3b. Extract purged primary and haplotig sequences ------
echo "[$(date)] Running get_seqs"
get_seqs \
    -e dups.bed \
    "${ASSEMBLY}"
# Outputs: purged.fa  hap.fa

# --- 3c. Assembly QC stats ----------------------------------
echo "[$(date)] Assembly statistics (purged primary — purged.fa):"
seqkit stats -a purged.fa

echo "[$(date)] Assembly statistics (haplotigs — hap.fa):"
seqkit stats -a hap.fa

echo ""
echo "============================================================"
echo " Pipeline complete — $(date)"
echo " Key outputs:"
echo "   Purged primary : ${OUTDIR}/purged.fa"
echo "   Haplotigs      : ${OUTDIR}/hap.fa"
echo "   Dup regions    : ${OUTDIR}/dups.bed"
echo "   Coverage log   : ${OUTDIR}/calcuts.log"
echo "   Purge log      : ${OUTDIR}/purge_dups.log"
echo "============================================================"

