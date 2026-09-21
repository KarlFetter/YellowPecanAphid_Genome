#!/bin/bash
#SBATCH --job-name=calc_coverage
#SBATCH --partition=ceres
#SBATCH --time=04:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

# Create output directory and change to it
mkdir -p coverage
cd coverage

# Load the required environment module
module load seqkit

# Static paths for the raw reads
HIFI_READS="/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_hifi.fastq.gz"
ONT_READS="/90daydata/tgl_seqdata/aphids/assembly/ypa/01_raw_reads/ypa_ont_reads_18kb_min.fastq.gz"

# Array of assembly file names (assuming they are in the parent 08_final_draft_assembly directory)
ASSEMBLY_DIR="/90daydata/tgl_seqdata/aphids/assembly/ypa/09_final_assembly"
ASSEMBLIES=(
    "ypa_hap1.cleaned.fa.gz"
    "ypa_hap2.cleaned.fa.gz"
    "ypa_primary.cleaned.fa.gz"
)

echo "Calculating total bases for raw reads once to save time..."
HIFI_BASES=$(seqkit stats -t dna -j "$SLURM_CPUS_PER_TASK" "$HIFI_READS" | awk 'NR==2 {gsub(/,/, "", $5); print $5}')
ONT_BASES=$(seqkit stats -t dna -j "$SLURM_CPUS_PER_TASK" "$ONT_READS" | awk 'NR==2 {gsub(/,/, "", $5); print $5}')

# Initialize the single output file with a header row
OUTPUT_FILE="all_assemblies_coverage.tsv"
echo -e "Assembly_File\tAssembly_Size_bp\tHiFi_Coverage\tONT_Coverage" > "$OUTPUT_FILE"

# Loop through each assembly file to calculate stats
for ASM in "${ASSEMBLIES[@]}"; do
    FULL_ASM_PATH="${ASSEMBLY_DIR}/${ASM}"
    
    echo "Processing assembly: $ASM..."
    
    # Calculate assembly size
    ASM_SIZE=$(seqkit stats "$FULL_ASM_PATH" | awk 'NR==2 {gsub(/,/, "", $5); print $5}')
    
    # Calculate coverages using awk
    HIFI_COV=$(awk "BEGIN {printf \"%.2f\", $HIFI_BASES / $ASM_SIZE}")
    ONT_COV=$(awk "BEGIN {printf \"%.2f\", $ONT_BASES / $ASM_SIZE}")
    
    # Append the row to the single output file (tab-separated)
    echo -e "${ASM}\t${ASM_SIZE}\t${HIFI_COV}X\t${ONT_COV}X" >> "$OUTPUT_FILE"
done

echo "Coverage calculation complete. Matrix saved to coverage/$OUTPUT_FILE"

