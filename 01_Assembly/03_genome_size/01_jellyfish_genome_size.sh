#!/bin/bash
#SBATCH --job-name=JELLYFISH_GENOMESIZE
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --mem=750G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load jellyfish2/2.2.9

# ============================================================
# K-mer counting for genome size estimation
# Upload histogram to GenomeScope2:
# http://qb.cshl.edu/genomescope/genomescope2.0/
# ============================================================

# Set up inputs
THREADS=8
KMER=21
HASH_SIZE=10G
READS=/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_hifi.fastq.gz
OUTDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/03_genome_size
PREFIX=ypa_k${KMER}

# Count k-mers
echo "$(date): Counting ${KMER}-mers..."
jellyfish count \
    -m ${KMER} \
    -s ${HASH_SIZE} \
    -t ${THREADS} \
    -C \
    -o ${PREFIX}.jf \
    <(zcat ${READS})

# Generate histogram
echo "$(date): Generating histogram..."
jellyfish histo \
    -t ${THREADS} \
    ${PREFIX}.jf \
    > ${PREFIX}.histo

echo "$(date): Done."
echo "Histogram: ${OUTDIR}/${PREFIX}.histo"
echo "Upload to GenomeScope2 (http://qb.cshl.edu/genomescope/genomescope2.0/) for genome size estimation"

