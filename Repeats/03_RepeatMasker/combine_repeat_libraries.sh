#!/bin/bash
#SBATCH --job-name=YPA_BUILD_REPEAT_LIB
#SBATCH --partition=ceres
#SBATCH --time=8:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --mem=64G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -e

WORK_DIR="/90daydata/tgl_seqdata/aphids/repeats/ypa/03_RepeatMasker"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

module load repeatmasker

# De novo curated consensus library (RepeatModeler → TEtrimmer output)
MODELER_OUT="/90daydata/tgl_seqdata/aphids/repeats/ypa/01_RepeatModeller/consensi.fa"

# RepBase v31.07 reference library directory
REPBASE_DIR="/project/tgl_seqdata/databases/RepBase/RepBase31.07.fasta"

echo "=== Step 1: Extracting curated Insecta families from FamDB ==="
famdb.py -i "$REPEATMASKER_LIB_DIR/RepeatMaskerLib.h5" families \
         --format fasta_name \
         --include-class-in-name \
         --ancestors \
         --descendants 'Insecta' > insecta_known.fa

echo "=== Step 2: Combining de novo, FamDB Insecta, and RepBase reference libraries ==="
# RepBase selections: drorep (Drosophila) and angrep (Anopheles) — well-characterized Insecta TEs
# simple.ref — macrosatellites/simple tandem repeats; pseudo.ref — retroposed pseudogenes
cat "$MODELER_OUT" \
    insecta_known.fa \
    "${REPBASE_DIR}/simple.ref" \
    "${REPBASE_DIR}/drorep.ref" \
    "${REPBASE_DIR}/angrep.ref" \
    "${REPBASE_DIR}/pseudo.ref" > unified_repeats.fa

echo "Unified library: $(grep -c '^>' unified_repeats.fa) total sequences"
echo "=== Library build complete ==="
