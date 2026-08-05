#!/bin/bash
#SBATCH --job-name=SEQ_LENGTH_HISTO
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --mem=4G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load seqkit

INPUT=YPA_ONT_reads_barcode_run.fastq.gz

# Generate the read_lengths file
seqkit fx2tab -l -n $INPUT | cut -f 2 > read_lengths.txt

# Plot it
python ~/methods/genomics/seq_length_histo.py


