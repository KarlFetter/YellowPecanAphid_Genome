#!/bin/bash
#SBATCH --job-name=CONCAT_ONT
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

# Load module
module load seqkit

# Set up the job
INPUT=/project/tgl_seqdata/barcoded_sequences/BMA4_BPA5_YPA6_CaquaR1T6/20260421_1552_P2I-00455-A_PBK06960_e4cde178/fastq_pass/barcode03/*fastq.gz 

# concat inputs
seqkit seq $INPUT -o YPA_ONT_reads_barcode_run.fastq.gz
