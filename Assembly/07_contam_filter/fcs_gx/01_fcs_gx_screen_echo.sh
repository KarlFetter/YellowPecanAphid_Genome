#!/bin/bash
#SBATCH --job-name=FCS_GX_SCREEN
#SBATCH --partition=ceres
#SBATCH --time=24:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=500G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

# ============================================================
# NCBI FCS-GX — Genome contamination screen
# Species: Yellow pecan aphid (Monellia caryella)
# ============================================================
# FCS-GX (Foreign Contamination Screen — Genome eXpanded) is
# NCBI's tool for detecting foreign sequence in genome
# assemblies prior to submission. NCBI runs this automatically
# on all submitted genomes; running it yourself prevents
# rejection and flags issues early.
#
# FCS-GX screens for:
#   - Bacterial, viral, and fungal contamination
#   - Sequences from other organisms co-assembled with target
#   - Spans larger taxonomic signal than BlobToolKit alone
#
# Memory requirement:
#   FCS-GX loads its database into memory (~470 GB). Request
#   500G to ensure enough headroom. The ceres large-memory
#   partition may be required: --partition=ceres-long or mem768
#
# Setup — FCS-GX database:
#   Download if not present (~110 GB compressed):
#     python3 fcs.py db get --mft https://ftp.ncbi.nlm.nih.gov/genomes/TOOLS/FCS/database/latest/all.manifest --dir /path/to/gxdb
#   Or contact HPC admins for a shared installation.
#
# NCBI Tax ID for Monellia caryella:
#   Look up at: https://www.ncbi.nlm.nih.gov/taxonomy
#   Search "Monellia caryella" and update TAXID below.
#
# Input:
#   purged.fa.scaffolds.fa — original scaffolded primary assembly
#                            (independent of BlobToolKit steps)
#
# Output:
#   fcs_output/*.fcs_gx_report.txt — contamination report
#   fcs_output/*.taxonomy.rpt      — taxonomy assignments
#
# Run order:
#   (independent of 01_blobtoolkit/ — can run in parallel)
#   01_fcs_gx_screen.sh  <-- this script
#   02_apply_fcs_filter.sh
# ============================================================

# Load required modules
module load apptainer

TAXID=527790   # ← REQUIRED: update with Monellia caryella NCBI taxid

ASSEMBLY=/90daydata/tgl_seqdata/aphids/assembly/ypa/06_scaffolding/samba_hifiasm_ul/hap2/purged.fa.scaffolds.fa
GX_DB=/project/tgl_seqdata/databases/fcs-gx/gxdb
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/08_contam_filter/fcs_gx/hap2

# Define the absolute path to your downloaded fcs.py script
FCS_SCRIPT="${HOME}/apptainer/fcs.py"
SIF_IMAGE="${HOME}/apptainer/fcs-gx.sif"

# Combine them into your execution call
FCS_PY="python3 ${FCS_SCRIPT} --image ${SIF_IMAGE}"

mkdir -p "${OUTDIR}"

# Print input resources
echo "[$(date)] Running FCS-GX genome screen"
echo "  Assembly : ${ASSEMBLY}"
echo "  Database : ${GX_DB}"
echo "  Tax ID   : ${TAXID}"
echo "  Output   : ${OUTDIR}"

# ── Genome contamination screen ──────────────────────────────
${FCS_PY} screen genome \
    --fasta "${ASSEMBLY}" \
    --out-dir "${OUTDIR}" \
    --gx-db "${GX_DB}" \
    --tax-id "${TAXID}"

# ── Summarize results ────────────────────────────────────────
echo ""
echo "[$(date)] FCS-GX screen complete"
echo ""

REPORT=$(find "${OUTDIR}" -name "*.fcs_gx_report.txt" | head -1)
if [[ -f "${REPORT}" ]]; then
    echo "  Report: ${REPORT}"
    echo ""
    echo "  --- Contamination summary ---"
    # Count action categories in the report
    echo "  EXCLUDE (remove entire sequence):"
    grep -c "EXCLUDE" "${REPORT}" || echo "  0"
    echo "  TRIM (remove partial sequence):"
    grep -c "TRIM"    "${REPORT}" || echo "  0"
    echo "  FIX (review manually):"
    grep -c "FIX"     "${REPORT}" || echo "  0"
    echo "  REVIEW:"
    grep -c "REVIEW"  "${REPORT}" || echo "  0"
fi

echo ""
echo "[$(date)] Next: run 02_apply_fcs_filter.sh to clean the assembly"

