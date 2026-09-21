#!/bin/bash
#SBATCH --job-name=index_ypa
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

# Load required cluster environments
module load minimap2
module load samtools

# Target assembly directory
ASSEMBLY_DIR="/90daydata/tgl_seqdata/aphids/assembly/ypa/09_final_assembly"

ASSEMBLIES=(
    "ypa_hap1.cleaned.fa.gz"
    "ypa_hap2.cleaned.fa.gz"
    "ypa_primary.cleaned.fa.gz"
)

# Loop through and index each assembly
for ASM in "${ASSEMBLIES[@]}"; do
    FULL_PATH="${ASSEMBLY_DIR}/${ASM}"
    
    echo "Indexing $ASM with samtools..."
    samtools faidx "$FULL_PATH"
    
    echo "Generating minimap2 .mmi index for $ASM..."
    # -d creates the index file name by replacing .fa.gz with .mmi
    OUTPUT_MMI="${FULL_PATH%.fa.gz}.mmi"
    minimap2 -d "$OUTPUT_MMI" "$FULL_PATH"
    
done

echo "All ypa genome indexing complete."

