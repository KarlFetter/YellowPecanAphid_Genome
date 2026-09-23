#!/bin/bash
#SBATCH --job-name=YPA_TE_MERGE
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --mem=4G
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

WORK_DIR="/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/data"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${WORK_DIR}"
python3 "${SCRIPT_DIR}/merge_pi.py" --workdir "${WORK_DIR}"