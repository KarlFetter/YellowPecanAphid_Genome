#!/bin/bash
#SBATCH --job-name=YPA_TEtrimmer
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 32
#SBATCH --mem=240G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

# ==================== CONFIGURATION ====================
PFAM_DIR="/project/tgl_seqdata/databases/pfam"
INPUT_LIB="/90daydata/tgl_seqdata/aphids/repeats/ypa/01_RepeatModeller/ypa_db-families.fa"
GENOME="/90daydata/tgl_seqdata/aphids/assembly/ypa/08_final_draft_assembly/ypa_primary.cleaned.fa.gz"
OUTDIR="/90daydata/tgl_seqdata/aphids/repeats/ypa/02_TEtrimmer_run1"
# =======================================================

# Initialize the TEtrimmer Conda environment.
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate TEtrimmer

# Force the compute node to prioritize this environment's binaries
export PATH="$CONDA_PREFIX/bin:$PATH"

mkdir -p "$OUTDIR"
cd "$OUTDIR"

echo "$(date): Starting TEtrimmer automated curation..."

# Run TEtrimmer with the curated RepeatModeler library.
TEtrimmer \
  -i "$INPUT_LIB" \
  -g "$GENOME" \
  --dedup \
  --min_blast_len 60 \
  --classify_unknown \
  --pfam_dir "$PFAM_DIR" \
  -t "$SLURM_CPUS_PER_TASK"



echo "$(date): TEtrimmer processing complete."
