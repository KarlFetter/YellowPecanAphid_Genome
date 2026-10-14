#!/bin/bash
#SBATCH --job-name=ONT_STATS
#SBATCH --partition=ceres
#SBATCH --time=120:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load seqkit

# ============================================================
# Calculate basic read statistics from ONT fastq files. 
# ============================================================

# Set up the job
THREADS=8
INDIR="/project/tgl_seqdata/barcoded_sequences/BMA4_BPA5_YPA6_CaquaR1T6/20260421_1552_P2I-00455-A_PBK06960_e4cde178/fastq_pass/barcode03"
OUTDIR="/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads"
PREFIX="ypa_ont_barcodeRun"

#Create stats
seqkit stats -a -j $THREADS "${INDIR}"/*.fastq.gz > "${OUTDIR}/${PREFIX}_stats.txt"
cat "${OUTDIR}/${PREFIX}_stats.txt"

