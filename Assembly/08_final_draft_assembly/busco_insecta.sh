#!/bin/bash
#SBATCH --job-name=BUSCO_Run
#SBATCH --partition=ceres
#SBATCH --time=48:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=300G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load busco5

# Paths
THREADS=16
BUSCO_DB=/project/tgl_seqdata/databases/BUSCO/busco_downloads/lineages/insecta_odb10
OUTDIR=busco
INDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/08_contam_filter/fcs_gx/primary
INDIR_HAP1=/90daydata/tgl_seqdata/aphids/assembly/ypa/08_contam_filter/fcs_gx/hap1
INDIR_HAP2=/90daydata/tgl_seqdata/aphids/assembly/ypa/08_contam_filter/fcs_gx/hap2
BASENAME=ypa

# Go to Analysis dir
mkdir -p ${OUTDIR}
cd ${OUTDIR}

# BUSCO run for the primary assembly
#busco \
#    -i "${INDIR}/${BASENAME}_primary.cleaned.fa" \
#    -o primary_busco \
#    -l ${BUSCO_DB} \
#    -m genome \
#    -f \
#    -c ${THREADS} \
#    --offline

# BUSCO run for hap1 assembly
busco \
    -i "${INDIR_HAP1}/${BASENAME}_hap1.cleaned.fa" \
    -o hap1_busco \
    -l ${BUSCO_DB} \
    -m genome \
    -f \
    -c ${THREADS} \
    --offline

# BUSCO run for hap1 assembly
busco \
    -i "${INDIR_HAP2}/${BASENAME}_hap2.cleaned.fa" \
    -o hap2_busco \
    -l ${BUSCO_DB} \
    -m genome \
    -f \
    -c ${THREADS} \
    --offline

