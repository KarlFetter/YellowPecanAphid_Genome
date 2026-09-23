#!/bin/bash
#SBATCH --job-name=YPA_HIFIASM_UL
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 64
#SBATCH --mem=500G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load hifiasm/0.25.0

# ============================================================
# hifiasm — HiFi + ONT ultra-long assembly
# Species: Yellow pecan aphid (Monelliopsis pecanis)
# Input: HiFi reads and raw ONT barcode reads
# ============================================================

THREADS=64
READS=/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_hifi.fastq.gz
ULREADS=/project/tgl_seqdata/barcoded_sequences/BMA4_BPA5_YPA6_CaquaR1T6/20260421_1552_P2I-00455-A_PBK06960_e4cde178/fastq_pass/barcode03
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/04_assembly/hifiasm_ul_ONTbarcodeReads
PREFIX=ypa_ul

mkdir -p ${OUTDIR}
cd ${OUTDIR}

hifiasm \
    -o ${PREFIX} \
    -t ${THREADS} \
    --ul ${ULREADS}/*.fastq.gz \
    ${READS}

