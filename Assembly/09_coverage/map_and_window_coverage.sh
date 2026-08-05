#!/bin/bash
#SBATCH --job-name=COVERAGE_MAPPING
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=300G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

# Define the root output directory
BASE_OUTPUT_DIR="/90daydata/tgl_seqdata/aphids/assembly/ypa/09_coverage"

# Load required cluster environments
module load minimap2
module load samtools
module load bedtools

# Static paths for the raw reads
HIFI_READS="/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_hifi.fastq.gz"
ONT_READS="/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_ont_reads_18kb_min.fastq.gz"

# Input assemblies location
ASSEMBLY_DIR="/90daydata/tgl_seqdata/aphids/assembly/ypa/08_final_draft_assembly"
ASSEMBLIES=(
    "ypa_primary.cleaned.fa.gz"
    "ypa_hap1.cleaned.fa.gz"
    "ypa_hap2.cleaned.fa.gz"
)

# Window size for genome-wide plotting (100 kb)
WINDOW_SIZE=100000

for ASM in "${ASSEMBLIES[@]}"; do
    FULL_ASM_PATH="${ASSEMBLY_DIR}/${ASM}"
    ASM_NAME=$(basename "$ASM" .cleaned.fa.gz)
    
    # Extract subfolder nickname (hap1, hap2, or primary)
    SUBDIR=$(echo "$ASM_NAME" | awk -F'_' '{print $2}')
    
    # Create the specific subfolder and change into it
    CURRENT_WORK_DIR="${BASE_OUTPUT_DIR}/${SUBDIR}"
    mkdir -p "$CURRENT_WORK_DIR"
    cd "$CURRENT_WORK_DIR"
    
    echo "=========================================================="
    echo "Processing $ASM_NAME inside: $CURRENT_WORK_DIR"
    echo "=========================================================="

    # Decompress the genome locally so samtools can index it cleanly without gzip error
    LOCAL_FASTA="${ASM_NAME}.fa"
    echo "Temporarily unzipping assembly..."
    zcat "$FULL_ASM_PATH" > "$LOCAL_FASTA"

    echo "Creating .fai index..."
    samtools faidx "$LOCAL_FASTA"

    # Create 100kb windows inside the specific subfolder using the local index
    echo "Creating ${WINDOW_SIZE}bp windows..."
    bedtools makewindows -g "${LOCAL_FASTA}.fai" -w "$WINDOW_SIZE" > "${ASM_NAME}_windows.bed"

    # Inner loop to process both HiFi and ONT reads independently
    for READ_TYPE in "hifi" "ont"; do
        if [ "$READ_TYPE" == "hifi" ]; then
            READS="$HIFI_READS"
            MODE="map-hifi"
        else
            READS="$ONT_READS"
            MODE="map-ont"
        fi
        
        PREFIX="${ASM_NAME}_${READ_TYPE}"
        BAM="${PREFIX}.sorted.bam"
        
        echo "Aligning $READ_TYPE reads to $ASM_NAME..."
        # FIXED memory safety balance: 16 threads x 6G = 96GB max sorting footprint.
        # Leaves ~144GB of massive safety headroom for minimap2's active index arrays.
        minimap2 -ax "$MODE" -t "$SLURM_CPUS_PER_TASK" "$LOCAL_FASTA" "$READS" | \
        samtools sort -@ "$SLURM_CPUS_PER_TASK" -m 6G -o "$BAM" -
        
        echo "Indexing final BAM file..."
        samtools index -@ "$SLURM_CPUS_PER_TASK" "$BAM"
        
        echo "Calculating windowed coverage matrix..."
        bedtools coverage -a "${ASM_NAME}_windows.bed" -b "$BAM" -mean > "${PREFIX}_100kb_coverage.txt"
    done

    # Clean up the heavy temporary uncompressed FASTA file
    echo "Cleaning up local temporary fasta text..."
    rm "$LOCAL_FASTA"
done

echo "QC workflow calculations complete. All files organized under $BASE_OUTPUT_DIR"

