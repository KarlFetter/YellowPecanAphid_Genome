#!/bin/bash
#SBATCH --job-name=MINIMAP_COVERAGE
#SBATCH --partition=ceres
#SBATCH --time=12:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem=64G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

# Create and move to output directory
mkdir -p minimap2_coverage
cd minimap2_coverage

# Load required cluster environments
module load minimap2
module load samtools

# File paths
HIFI_READS="/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_hifi.fastq.gz"
ONT_READS="/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_ont_reads_18kb_min.fastq.gz"
ASSEMBLY_DIR="/90daydata/tgl_seqdata/aphids/assembly/ypa/09_final_assembly"

ASSEMBLIES=(
    "ypa_hap1.cleaned.fa.gz"
    "ypa_hap2.cleaned.fa.gz"
    "ypa_primary.cleaned.fa.gz"
)

# Initialize output report
OUTPUT_REPORT="empirical_coverage_summary.tsv"
echo -e "Assembly_File\tHiFi_Mapped_Depth\tHiFi_Breadth_%\tONT_Mapped_Depth\tONT_Breadth_%" > "$OUTPUT_REPORT"

# Function to run mapping and capture true depth
get_alignment_depth() {
    local REF=$1
    local READS=$2
    local MODE=$3       # "map-hifi" or "map-ont"
    local PREFIX=$4     # e.g., "hap1_hifi"
    
    echo "  Aligning reads for ${PREFIX}..."
    # Map with minimap2, convert to BAM, sort, and save using multi-threading
    minimap2 -ax "$MODE" -t "$SLURM_CPUS_PER_TASK" "$REF" "$READS" | \
    samtools sort -@ "$SLURM_CPUS_PER_TASK" -m 3G -o "${PREFIX}.sorted.bam" -
    
    echo "  Calculating empirical depth for ${PREFIX}..."
    # Parse the global summary line from samtools coverage table
    # Columns extracted: $6 = mean depth, $7 = percentage of genome covered (breadth)
    local STATS=$(samtools coverage "${PREFIX}.sorted.bam" | awk '
        NR > 1 {
            bases += ($3 - $2 + 1); 
            depth_sum += ($6 * ($3 - $2 + 1)); 
            cov_sum += ($7 * ($3 - $2 + 1))
        } 
        END {
            printf "%.2f\t%.2f", depth_sum/bases, cov_sum/bases
        }
    ')
    
    # Clean up the BAM to save server space
    rm "${PREFIX}.sorted.bam"
    
    echo "$STATS"
}

# Core loop through the assemblies
for ASM in "${ASSEMBLIES[@]}"; do
    FULL_ASM_PATH="${ASSEMBLY_DIR}/${ASM}"
    ASM_NAME=$(basename "$ASM" .cleaned.fa.gz)
    
    echo "==========================================="
    echo "Processing Genome Assembly: $ASM"
    echo "==========================================="
    
    # Process HiFi Alignment
    HIFI_STATS=$(get_alignment_depth "$FULL_ASM_PATH" "$HIFI_READS" "map-hifi" "${ASM_NAME}_hifi")
    
    # Process ONT Alignment
    ONT_STATS=$(get_alignment_depth "$FULL_ASM_PATH" "$ONT_READS" "map-ont" "${ASM_NAME}_ont")
    
    # Output metrics to file
    echo -e "${ASM}\t${HIFI_STATS}\t${ONT_STATS}" >> "$OUTPUT_REPORT"
done

echo "Empirical coverage analysis complete. Matrix generated in minimap2_coverage/$OUTPUT_REPORT"

