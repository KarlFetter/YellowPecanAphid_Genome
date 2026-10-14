#!/bin/bash
#SBATCH --job-name=YPA_HIFIASM
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 64
#SBATCH --mem=750G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load hifiasm/0.25.0

# ============================================================
# hifiasm — HiFi-only assembly
# Species: Yellow pecan aphid (Monelliopsis pecanis)
# Input: HiFi reads directly from Vega
# ============================================================

THREADS=64
READS=/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_hifi.fastq.gz
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/04_assembly/hifiasm
PREFIX=ypa

mkdir -p ${OUTDIR}
cd ${OUTDIR}

# Run hifiasm for HiFi-only assembly
hifiasm \
    -o ${PREFIX} \
    -t ${THREADS} \
    ${READS}
