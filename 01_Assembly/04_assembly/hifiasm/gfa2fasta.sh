#!/bin/bash
#SBATCH --job-name=GFA_TO_FASTA
#SBATCH --partition=ceres
#SBATCH --time=12:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --mem=32G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

# ============================================================
# Convert hifiasm GFA output to FASTA
# ============================================================

INDIR=/90daydata/tgl_seqdata/aphids/assembly/ypa/04_assembly/hifiasm

P_CTG=${INDIR}/ypa.bp.p_ctg.gfa
HAP1=${INDIR}/ypa.bp.hap1.p_ctg.gfa
HAP2=${INDIR}/ypa.bp.hap2.p_ctg.gfa

# Convert primary contigs
awk '/^S/{print ">"$2; print $3}' ${P_CTG} | gzip -c > ${INDIR}/ypa.bp.p_ctg.fa.gz

# Convert haplotype 1
awk '/^S/{print ">"$2; print $3}' ${HAP1} | gzip -c > ${INDIR}/ypa.bp.hap1.p_ctg.fa.gz

# Convert haplotype 2
awk '/^S/{print ">"$2; print $3}' ${HAP2} | gzip -c > ${INDIR}/ypa.bp.hap2.p_ctg.fa.gz

ls -lh ${INDIR}/ypa.bp.*.fa.gz

