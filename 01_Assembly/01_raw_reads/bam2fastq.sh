#!/bin/bash
#SBATCH --job-name=BAM2FASTQ
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

# Load the module
module load samtools

# ============================================================
# Convert PacBio HiFi BAM to FASTQ
# Species: Yellow pecan aphid (Monelliopsis pecanis)
# ============================================================

# Set up the job
THREADS=8
INBAM=/project/tgl_seqdata/insect/yellow_pecan_aphid/r21129_20260514_201441/1_A01/hifi_reads/m21129_260514_201920.hifi_reads.bam
OUTDIR=./
PREFIX=ypa_hifi

mkdir -p ${OUTDIR}

echo "$(date): Converting BAM to FASTQ..."

# Convert BAM to FASTQ using samtools
samtools fastq \
    -@ ${THREADS} \
    ${INBAM} | gzip > ${OUTDIR}/${PREFIX}.fastq.gz

echo "$(date): Conversion complete."
echo "$(date): Output: ${OUTDIR}/${PREFIX}.fastq.gz"

# Quick stats
module load seqkit
seqkit stats -a ${OUTDIR}/${PREFIX}.fastq.gz > ${OUTDIR}/${PREFIX}_stats.txt
cat ${OUTDIR}/${PREFIX}_stats.txt

