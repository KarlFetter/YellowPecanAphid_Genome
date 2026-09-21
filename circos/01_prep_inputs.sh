#!/bin/bash
#SBATCH --job-name=YPA_PREP_CIRCOS
#SBATCH --partition=ceres
#SBATCH --time=01:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -e

module load seqkit
module load samtools
module load bcftools

# ----------------------------------------------------
# CONFIGURATION PATHS
# ----------------------------------------------------
GENOME="ypa_primary_top6.fasta"
VCF="ypa_DP10_220_biallelic_top6_renamed.vcf.gz"
WORK_DIR="/90daydata/tgl_seqdata/aphids/circos/ypa/primary"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# ----------------------------------------------------
# 1. INDEX THE GENOME WITH NEW SCAFFOLD NAMES
# ----------------------------------------------------

samtools faidx $GENOME

# Build the structural karyotype file for circlize
awk '{print $1 "\t0\t" $2}' "${GENOME}.fai" > ypa_karyotype.txt

# ----------------------------------------------------
# 2. EXTRACT 10KB SLIDING WINDOW SNP DENSITY
# ----------------------------------------------------
# Stream coordinates directly from your top6 VCF to build the window density file
bcftools query -f '%CHROM\t%POS\n' "$VCF" | \
awk '{window=int($2/10000)*10000; print $1"\t"window"\t"window+10000}' | \
sort | uniq -c | \
awk '{print $2"\t"$3"\t"$4"\t"$1}' > ypa_snp_density_10kb.txt

# ----------------------------------------------------
# 3. CALCULATE PI IN 10KB WINDOWS
# ----------------------------------------------------
module load vcftools

vcftools --gzvcf "$VCF" \
	--window-pi 10000 \
	--window-pi-step 10000 \
	--out ypa_pi_10kb
