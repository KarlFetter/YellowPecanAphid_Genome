#!/bin/bash
#SBATCH --job-name=YPA_FIXED_PI
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

WORK_DIR="/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/fixed_windows_approach"
VCF="/90daydata/tgl_seqdata/aphids/popgen/ypa/01_snps/ypa_DP10_220_biallelic_top6.vcf.gz"

module load vcftools/0.1.17
command -v vcftools >/dev/null || { echo "vcftools/0.1.17 is required" >&2; exit 1; }

mkdir -p "${WORK_DIR}"
[[ -s "${VCF}" ]] || { echo "Missing VCF: ${VCF}" >&2; exit 1; }
[[ -s "${WORK_DIR}/genome_10kb_te_annotations.tsv" ]] || { echo "Run 01_make_fixed_windows.sh first" >&2; exit 1; }

cd "${WORK_DIR}"
for size in 5000 10000; do
    prefix="genome_$((size / 1000))kb"
    vcftools --gzvcf "${VCF}" --window-pi "${size}" --window-pi-step "${size}" --out "${WORK_DIR}/${prefix}"
    [[ -s "${prefix}.windowed.pi" ]] || { echo "Missing ${prefix}.windowed.pi" >&2; exit 1; }

    annotation_file="${prefix}_te_annotations.tsv"
    output_file="${prefix}_pi.tsv"
    awk -F '\t' -v size="${size}" -v pi_file="${prefix}.windowed.pi" 'BEGIN { OFS = "\t" }
        FILENAME != pi_file {
            if (FNR == 1) { annotation_header = $0; next }
            annotations[$2 FS $3 FS $4] = $0
            next
        }
        FNR == 1 {
            print annotation_header, "N_VARIANTS", "N_MONOMORPHIC", "PI"
            next
        }
        {
            key = $1 FS $2 FS $3
            if (key in annotations) {
                print annotations[key], $4, $5, $6
            } else {
                id = "VCFTOOLS_" $1 "_" $2 "_" $3
                print id, $1, $2, $3, size, "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", $4, $5, $6
            }
        }
    ' "${annotation_file}" "${prefix}.windowed.pi" > "${output_file}"

    [[ $(wc -l < "${output_file}") -gt 1 ]] || {
        echo "No VCFtools windows were joined for ${output_file}" >&2
        exit 1
    }
    echo "Created ${output_file} ($(wc -l < "${output_file}") lines)"
done

head -n 1 genome_10kb_pi.tsv > fixed_windows_all_pi.tsv
tail -n +2 genome_5kb_pi.tsv >> fixed_windows_all_pi.tsv
tail -n +2 genome_10kb_pi.tsv >> fixed_windows_all_pi.tsv

echo "Fixed-window VCFtools calculations completed in ${WORK_DIR}"