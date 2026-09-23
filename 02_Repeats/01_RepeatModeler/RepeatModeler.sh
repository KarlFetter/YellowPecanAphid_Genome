#!/bin/bash
#SBATCH --job-name=YPA_REPEATMODELER
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 36
#SBATCH --mem=250G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

# 1. CREATE AND MOVE TO THE WORKSPACE
WORK_DIR="/90daydata/tgl_seqdata/aphids/genome_biology/repeats/ypa/01_RepeatModeller"

# 2. LOAD REPEATMODELER MODULE Environment
module load repeatmodeler

# Define paths and variable tokens
SPECIES="ypa"
GENOME="/90daydata/tgl_seqdata/aphids/assembly/ypa/07_contam_filter/fcs_gx/primary/ypa_primary.cleaned.fa"
DB_NAME="${SPECIES}_db"

echo "=== Step A: Building RepeatModeler Database for ${SPECIES} ==="
BuildDatabase -name "$DB_NAME" "$GENOME"

echo "=== Step B: Running De Novo Repeat Discovery ==="
# -pa specifies parallel execution threads (using 4 cores per search task thread)
# -LTRStruct runs structural discovery models for Long Terminal Repeats (highly recommended for insects)
RepeatModeler -database "$DB_NAME" \
              -threads $SLURM_CPUS_PER_TASK \
              -LTRStruct

echo "=== RepeatModeler Analysis Complete ==="
