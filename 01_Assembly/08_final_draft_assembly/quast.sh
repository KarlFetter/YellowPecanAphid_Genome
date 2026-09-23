#!/bin/bash
#SBATCH --job-name=QUAST
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --mem=4G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load quast

THREADS=8

# Set up Paths
OUTDIR=quast
INPUT=/90daydata/tgl_seqdata/aphids/assembly/ypa/09_final_assembly/ypa_hap2.cleaned.fa.gz

# Go to Analysis dir
mkdir -p ${OUTDIR}
cd ${OUTDIR}

# Run QUAST with basic options
quast \
    -o "${OUTDIR}/hap2" \
    -t $THREADS \
    $INPUT
