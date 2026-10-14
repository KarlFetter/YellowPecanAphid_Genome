#!/bin/bash
#SBATCH --job-name=FCS_GX_CLEAN
#SBATCH --partition=ceres
#SBATCH --time=4:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

# Load modules & Set up apptainer/singularity
module load apptainer || module load singularity || true
set -euo pipefail

export APPTAINER_BIND="/90daydata/tgl_seqdata:/90daydata/tgl_seqdata,/project/tgl_seqdata:/project/tgl_seqdata"
export SINGULARITY_BIND="/90daydata/tgl_seqdata:/90daydata/tgl_seqdata,/project/tgl_seqdata:/project/tgl_seqdata"

SIF_IMAGE="${HOME}/apptainer/fcs-gx.sif"

# ── ADJUST THESE PATHS AS NEEDED ─────────────────────
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/08_contam_filter/fcs_gx/hap2
INPUT=/90daydata/tgl_seqdata/aphids/assembly/ypa/06_scaffolding/samba_hifiasm_ul/hap2/purged.fa.scaffolds.fa
OUTFILE=ypa_hap2.cleaned.fa
# ─────────────────────────────────────────────────────────────

mkdir -p "${OUTDIR}"
cd "${OUTDIR}"

# 1. Set the FCS report file
REPORTS=( *.fcs_gx_report.txt )
FCS_REPORT="${REPORTS[0]}"

# 2. Run the FCS clean-genome command
singularity exec "${SIF_IMAGE}" /app/bin/gx clean-genome \
  -i "${INPUT}" \
  --action-report="${OUTDIR}/${FCS_REPORT}" \
  --output="${OUTDIR}/${OUTFILE}"

