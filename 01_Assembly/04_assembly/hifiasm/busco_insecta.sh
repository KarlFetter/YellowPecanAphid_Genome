#!/bin/bash
#SBATCH --job-name=BUSCO_Run
#SBATCH --partition=ceres
#SBATCH --time=48:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=300G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load busco5

# Paths
THREADS=16
BUSCO_DB=/project/tgl_seqdata/databases/BUSCO/busco_downloads/lineages/insecta_odb10
OUTDIR=busco
INDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/04_assembly/hifiasm
BASENAME=ypa

# Unzip fasata files
gunzip -k "${BASENAME}.bp.p_ctg.fa.gz"
gunzip -k "${BASENAME}.bp.hap1.p_ctg.fa.gz"
gunzip -k "${BASENAME}.bp.hap2.p_ctg.fa.gz"

# Go to Analysis dir
mkdir -p ${OUTDIR}
cd ${OUTDIR}

# BUSCO run for the primary assembly
busco \
    -i "${INDIR}/${BASENAME}.bp.p_ctg.fa" \
    -o primary_busco \
    -l ${BUSCO_DB} \
    -m genome \
    -f \
    -c ${THREADS} \
    --offline

# BUSCO run for hap1 assembly
busco \
    -i "${INDIR}/${BASENAME}.bp.hap1.p_ctg.fa" \
    -o hap1_busco \
    -l ${BUSCO_DB} \
    -m genome \
    -f \
    -c ${THREADS} \
    --offline

# BUSCO run for hap1 assembly
busco \
    -i "${INDIR}/${BASENAME}.bp.hap2.p_ctg.fa" \
    -o hap2_busco \
    -l ${BUSCO_DB} \
    -m genome \
    -f \
    -c ${THREADS} \
    --offline

