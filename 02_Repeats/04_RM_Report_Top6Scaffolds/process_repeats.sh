#!/bin/bash
#SBATCH --job-name=MAKE_TBL
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --mem=16G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

module load repeatmasker

COMBINED_LIB=/90daydata/tgl_seqdata/aphids/repeats/ypa/03_RepeatMasker/combined_refined_aphid_repeats.fa
MASKED_GENOME=/90daydata/tgl_seqdata/aphids/assembly/ypa/10_soft_masked_draft/ypa_primary.fa

ProcessRepeats \
  -lib ../03_RepeatMasker/combined_refined_aphid_repeats.fa \
  -maskSource $MASKED_GENOME \
  -excln \
  ypa_primary_top6.fa.cat
