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

module load apptainer || module load singularity || true
set -euo pipefail

TAXID=2982816 
ASSEMBLY=/90daydata/tgl_seqdata/aphids/assembly/ypa/06_scaffolding/samba_hifiasm_ul/primary/purged.fa.scaffolds.fa
GX_DB=/project/tgl_seqdata/databases/fcs-gx/gxdb
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/08_contam_filter/fcs_gx/primary
FCS_SCRIPT="${HOME}/apptainer/fcs.py"
SIF_IMAGE="${HOME}/apptainer/fcs-gx.sif"

mkdir -p "${OUTDIR}"

python3 "${FCS_SCRIPT}" --image "${SIF_IMAGE}" screen genome \
  --fasta "${ASSEMBLY}" \
  --out-dir "${OUTDIR}" \
  --gx-db "${GX_DB}" \
  --tax-id "${TAXID}"

