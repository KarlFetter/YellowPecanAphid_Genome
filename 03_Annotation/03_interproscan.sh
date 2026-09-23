#!/bin/bash
#SBATCH --job-name=IPRSCAN_YPA
#SBATCH --partition=ceres
#SBATCH --time=72:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 24
#SBATCH --mem=300G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

module load interproscan/5.78-109.0

PROTEINS="/90daydata/tgl_seqdata/aphids/annotation/ypa/funannotate/hemiptera_output/annotate_results/Monelliopsis_pecanis_YPA.proteins.fa"
OUT_DIR="/90daydata/tgl_seqdata/aphids/annotation/ypa/funannotate/hemiptera_output/annotate_results/iprscan"

# ProSiteProfiles was excluded because pftools failed on the cluster.
APPLICATIONS="CDD,Coils,Gene3D,Hamap,MobiDBLite,PANTHER,Pfam,PIRSF,PRINTS,ProSitePatterns,SFLD,SMART,SUPERFAMILY,TIGRFAM"

mkdir -p "$OUT_DIR"
sed 's/\*$//' "$PROTEINS" > "$OUT_DIR/proteins_nostop.fa"

interproscan.sh \
  -i "$OUT_DIR/proteins_nostop.fa" \
  -b "$OUT_DIR/Monelliopsis_pecanis_YPA" \
  -f XML \
  --goterms \
  --pathways \
  --cpu "$SLURM_CPUS_PER_TASK" \
  --appl "$APPLICATIONS"
