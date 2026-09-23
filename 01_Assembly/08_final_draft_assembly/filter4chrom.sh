#!/bin/bash
#SBATCH --job-name=
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --mem=4G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load seqkit

# Only select final seqs for primary.
# As of now, it is unclear which scaffolds are chromosomes for Hap1 and Hap2

PRIMARY=/90daydata/tgl_seqdata/aphids/assembly/ypa/06_scaffolding/samba_hifiasm_ul/primary/purged.fa.scaffolds.fa

# Select the top 6 sequences corresponding to chromosomes
seqkit sort --by-length --reverse $PRIMARY | seqkit head -n 6 > ypa.primary.chrom.fasta.gz

