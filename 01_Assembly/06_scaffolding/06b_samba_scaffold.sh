#!/bin/bash
#SBATCH --job-name=SAMBA_SCAFFOLD
#SBATCH --partition=ceres
#SBATCH --time=24:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
#SBATCH --mem=128G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load masurca/4.1.0

set -euo pipefail

# ============================================================
# SAMBA — HiFi-read scaffolding and gap-filling from contigs
# ============================================================
# SAMBA scaffolds and gap-fills directly from HiFi contigs in
# a single step (-d asm mode). Unlike ntLink, gap sequences are
# filled with real sequence rather than N-pads, yielding longer
# contigs and a more contiguous assembly.
#
# Input:
#   purged.fa            — purged primary contigs
#                          (05_purge_haplotigs/hifiasm/)
#   ypa_hifi.fastq.gz   — raw HiFi reads
#
# Key parameters:
#   -d asm   — data type for PacBio HiFi reads
#   -m 2500  — minimum matching length; 2500 for small genomes
#              (<400 Mb); aphid genomes typically 300–500 Mb
#   -t       — threads
#
# Output: purged.fa.scaffolds.fa → renamed to ypa_primary.fa
#
# Run order:
#   (after 05_purge_haplotigs/03_purge.sh)
#   01_samba_scaffold.sh  <-- this script
#   02_scaffold_qc.sh
# ============================================================

THREADS=32
ASSEMBLY=/90daydata/tgl_seqdata/aphids/assembly/ypa/05_purge_haplotigs/hifiasm_ul_34kbN50/hap2/purged.fa
READS=/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_hifi.fastq.gz
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/06_scaffolding/samba_hifiasm_ul/hap2

mkdir -p "${OUTDIR}"
cd "${OUTDIR}"

# Verify inputs exist
[[ -f "${ASSEMBLY}" ]] || { echo "ERROR: Purged assembly not found: ${ASSEMBLY}"; exit 1; }
[[ -f "${READS}" ]]    || { echo "ERROR: Reads not found: ${READS}"; exit 1; }

echo "[$(date)] Starting SAMBA scaffolding + gap-filling"
echo "  Assembly:  ${ASSEMBLY}"
echo "  Reads:     ${READS}"
echo "  Mode:      -d asm (PacBio HiFi)"
echo "  Min match: 2500 bp"
echo "  Threads:   ${THREADS}"

samba.sh \
    -r "${ASSEMBLY}" \
    -q "${READS}" \
    -d asm \
    -m 2500 \
    -t ${THREADS}

echo "[$(date)] SAMBA complete"

