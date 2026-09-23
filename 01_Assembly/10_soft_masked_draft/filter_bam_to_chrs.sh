#!/bin/bash
#SBATCH --job-name=ypa_filter_bam
#SBATCH --partition=ceres
#SBATCH --time=04:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

##
# This script filter the bam file in 09_coverage to just include the 6 chromosomes.
##

module load samtools

# Define paths
INPUT_BAM="/90daydata/tgl_seqdata/aphids/assembly/ypa/09_coverage/primary/ypa_primary_hifi.sorted.bam"
OUT_DIR="/90daydata/tgl_seqdata/aphids/assembly/ypa/10_soft_masked_draft"
OUTPUT_BAM="${OUT_DIR}/ypa_primary_hifi_6chr.sorted.bam"


# Extract only the 6 primary chromosomes into a new BAM file
# -b: output BAM format
# -@ 4: use 4 threads for speed
samtools view -b -@ 4 $INPUT_BAM \
    ptg000001l_1 \
    ptg000004l_1 \
    ptg000003l_1 \
    ptg000002l_1 \
    ptg000005l_1 \
    ptg000006l_1 \
    -o $OUTPUT_BAM

# Index the new filtered BAM file for downstream tools like WhatsHap
samtools index -@ 4 $OUTPUT_BAM

