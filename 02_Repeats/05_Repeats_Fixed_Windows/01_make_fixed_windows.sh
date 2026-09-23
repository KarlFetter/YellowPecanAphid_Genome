#!/bin/bash
#SBATCH --job-name=YPA_FIXED_WINDOWS
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

WORK_DIR="/90daydata/tgl_seqdata/aphids/repeats/ypa/05b_Repeats_GeneticDiv/fixed_windows"
GENOME="/90daydata/tgl_seqdata/aphids/assembly/ypa/10_soft_masked_draft/ypa_primary_top6.fa"
REPEAT_TSV="/90daydata/tgl_seqdata/aphids/repeats/ypa/04b_RepeatAge/repeat_ages_kimura.tsv"

module load samtools
module load bedtools
command -v awk >/dev/null || { echo "awk is required" >&2; exit 1; }
command -v bedtools >/dev/null || { echo "bedtools is required" >&2; exit 1; }

mkdir -p "${WORK_DIR}"
[[ -s "${GENOME}" ]] || { echo "Missing genome: ${GENOME}" >&2; exit 1; }
[[ -s "${REPEAT_TSV}" ]] || { echo "Missing repeat TSV: ${REPEAT_TSV} (run 00_extract_kimura_align.sh first)" >&2; exit 1; }

if [[ ! -s "${GENOME}.fai" ]]; then
    samtools faidx "${GENOME}"
fi

# repeat_order/repeat_class/unique_insertion_id come from circos/extract_kimura_align.py
TE_BED="${WORK_DIR}/te_intervals.bed"
awk -F '\t' 'BEGIN { OFS = "\t" }
    /^#/ { next }
    !header_seen { for (i = 1; i <= NF; i++) header[$i] = i; header_seen = 1; next }
    {
        if ($header["repeat_presence"] != "TE") next
        start = $header["position_begin"] - 1
        end = $header["position_end"]
        if (start < 0 || end <= start) next
        print $header["query_sequence"], start, end, $header["unique_insertion_id"], $header["repeat_order"], $header["repeat_class"], $header["repeat_family"], $header["kimura_percent"]
    }
' "${REPEAT_TSV}" | sort -k1,1 -k2,2n > "${TE_BED}"

for size in 5000 10000; do
    prefix="genome_$((size / 1000))kb"
    windows="${WORK_DIR}/${prefix}_windows.bed"
    annotated="${WORK_DIR}/${prefix}_te_annotations.tsv"
    body="${WORK_DIR}/${prefix}_te_annotations.body.tsv"

    bedtools makewindows -g "${GENOME}.fai" -w "${size}" > "${windows}"
    bedtools intersect -a "${windows}" -b "${TE_BED}" -wao | \
    awk -F '\t' -v size="${size}" 'BEGIN { OFS = "\t" }
        {
            key = $1 FS $2 FS $3
            if (!(key in seen)) {
                seen[key] = 1; chrom[key] = $1; start[key] = $2; end[key] = $3
                order[key] = ""; class_col[key] = ""; family[key] = ""; age_sum[key] = 0; age_count[key] = 0
                te_bp[key] = 0; n_te[key] = 0; ids[key] = ""
            }
            overlap = $(NF)
            if ($7 != "." && overlap > 0) {
                te_bp[key] += overlap; n_te[key]++
                if (order[key] == "") order[key] = $8
                else if (index(";" order[key] ";", ";" $8 ";") == 0) order[key] = order[key] ";" $8
                if (class_col[key] == "") class_col[key] = $9
                else if (index(";" class_col[key] ";", ";" $9 ";") == 0) class_col[key] = class_col[key] ";" $9
                if (family[key] == "") family[key] = $10
                else if (index(";" family[key] ";", ";" $10 ";") == 0) family[key] = family[key] ";" $10
                if ($11 != "" && $11 != "." && $11 != "NA") { age_sum[key] += $11; age_count[key]++ }
                if (ids[key] == "") ids[key] = $7
                else ids[key] = ids[key] ";" $7
            }
        }
        END {
            for (key in seen) {
                id = chrom[key] "_" (start[key] + 1) "_" end[key]
                age = (age_count[key] ? sprintf("%.6f", age_sum[key] / age_count[key]) : "NA")
                print id, chrom[key], start[key] + 1, end[key], size, te_bp[key], sprintf("%.8f", te_bp[key] / (end[key] - start[key])), n_te[key], (n_te[key] ? "TRUE" : "FALSE"), (order[key] ? order[key] : "NONE"), (class_col[key] ? class_col[key] : "NONE"), (family[key] ? family[key] : "NONE"), age, (ids[key] ? ids[key] : "NONE")
            }
        }' > "${body}"

    {
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "ID" "CHROM" "BIN_START" "BIN_END" "WINDOW_SIZE" "TE_BP" \
            "TE_FRACTION" "N_TE" "TE_PRESENT" "ORDER" "CLASS" "FAMILY" \
            "MEAN_KIMURA_PERCENT" "TE_IDS"
        sort -t $'\t' -k2,2 -k3,3n "${body}"
    } > "${annotated}"

    [[ -s "${annotated}" ]] || { echo "Failed to create ${annotated}" >&2; exit 1; }
    rm -f "${body}"
done

for output in "${WORK_DIR}/genome_5kb_te_annotations.tsv" "${WORK_DIR}/genome_10kb_te_annotations.tsv"; do
    [[ -s "${output}" ]] || { echo "Missing expected output: ${output}" >&2; exit 1; }
    echo "Created ${output} ($(wc -l < "${output}") lines)"
done

echo "Fixed-window files created in ${WORK_DIR}"
