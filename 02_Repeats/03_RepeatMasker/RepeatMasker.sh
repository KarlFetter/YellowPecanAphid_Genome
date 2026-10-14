#!/bin/bash
#SBATCH --job-name=REPEATMASKER
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 36
#SBATCH --mem=250G
#SBATCH --mail-type=END
#SBATCH -A tgl_seqdata

set -e

# Set working dir and create it
WORK_DIR="/90daydata/tgl_seqdata/aphids/repeats/ypa/02_RepeatMasker"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Load module
module load repeatmasker

# Define inputs
GENOME="/90daydata/tgl_seqdata/aphids/assembly/ypa/09_final_assembly/ypa_primary.cleaned.fa"
MODELER_OUT="/90daydata/tgl_seqdata/aphids/assembly/ypa/01_RepeatModeller/consensi.fa"
REPBASE_DIR="/project/tgl_seqdata/databases/RepBase/RepBase31.07.fasta"

echo "=== Step 1: Extracting curated Insecta elements via FamDB ==="
famdb.py -i $REPEATMASKER_LIB_DIR/RepeatMaskerLib.h5 families \
         --format fasta_name \
         --include-class-in-name \
         --ancestors \
         --descendants 'Insecta' > insecta_known.fa

echo "=== Step 2: Merging De Novo Repeats, FamDB, and Local RepBase Target Libraries ==="
cat "$MODELER_OUT" \
    insecta_known.fa \
    "${REPBASE_DIR}/simple.ref" \
    "${REPBASE_DIR}/drorep.ref" \
    "${REPBASE_DIR}/angrep.ref" \
    "${REPBASE_DIR}/pseudo.ref" > unified_repeats.fa

echo "=== Step 3: Running RepeatMasker in soft-masking configuration ==="
RepeatMasker -threads $SLURM_CPUS_PER_TASK \
             -e ncbi \
             -lib unified_repeats.fa \
             -xsmall \
             -gff \
             -dir "$WORK_DIR" \
             "$GENOME"

echo "=== Repeat Masking Workflow Complete ==="
