#!/bin/bash
#SBATCH --job-name=YPA_ONT_HIFIASM
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 64
#SBATCH --mem=500G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load hifiasm/0.25.0

# ============================================================
# hifiasm — Assemble ONT simplex reads with hifiasm --ont
# Species: Yellow Pecan Aphid
# Input: ONT simplex reads
# ============================================================

THREADS=64
ULREADS=/project/tgl_seqdata/barcoded_sequences/BMA4_BPA5_YPA6_CaquaR1T6/20260421_1552_P2I-00455-A_PBK06960_e4cde178/fastq_pass/barcode03
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/04_assembly/ont_hifiasm
PREFIX=ypa_ont

mkdir -p ${OUTDIR}
cd ${OUTDIR}

hifiasm \
    -o ${PREFIX} \
    -t ${THREADS} \
    --ont ${ULREADS}/*.fastq.gz

