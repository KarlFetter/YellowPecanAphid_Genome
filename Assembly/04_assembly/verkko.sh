#!/bin/bash
#SBATCH --job-name=YPA_VERKKO
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

# Set up
VERKKO=/home/karl.fetter/.conda/envs/verkko/bin/verkko

THREADS=64
READS=/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_hifi.fastq.gz
ULREADS=/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_ont_reads_18kb_min.fastq.gz
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/04_assembly/verkko
PREFIX=ypa_ul

mkdir -p ${OUTDIR}
cd ${OUTDIR}

$VERKKO \
	-d $OUTDIR \
	--hifi $READS \
       	--nano $ULREADS

