#!/bin/bash
#SBATCH --job-name=YPA_FIX_ANNOTS
#SBATCH --partition=ceres
#SBATCH --time=180:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --mem=4G
#SBATCH --mail-user=karl.fetter@usda.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -A tgl_seqdata

set -euo pipefail

# Reclassifies ORDER/CLASS using an exact unique_insertion_id lookup against the raw
# repeat TSV, without rerunning bedtools makewindows/intersect or vcftools --window-pi.
WORK_DIR="/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/fixed_windows_approach/fix"
REPEAT_TSV="/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/data/repeat_locations_types_k2_Complete_and_Fragmentary.tsv"
cd "${WORK_DIR}"

command -v awk >/dev/null || { echo "awk is required" >&2; exit 1; }
[[ -s "${REPEAT_TSV}" ]] || { echo "Missing ${REPEAT_TSV}" >&2; exit 1; }

for size in 5000 10000; do
    prefix="genome_$((size / 1000))kb"
    old_annotation="${prefix}_te_annotations.tsv"
    old_pi="${prefix}_pi.tsv"
    new_annotation="${prefix}_te_annotations.tsv.new"
    new_pi="${prefix}_pi.tsv.new"

    [[ -s "${old_annotation}" ]] || { echo "Missing ${old_annotation}" >&2; exit 1; }
    [[ -s "${old_pi}" ]] || { echo "Missing ${old_pi}" >&2; exit 1; }

    # Rebuild ORDER/CLASS via unique_insertion_id lookup (TE_IDS), not by parsing FAMILY text.
    awk -F '\t' -v OFS='\t' -v repeat_tsv="${REPEAT_TSV}" '
        BEGIN {
            header_seen = 0
            while ((getline line < repeat_tsv) > 0) {
                if (line ~ /^#/) continue
                n = split(line, cols, "\t")
                if (!header_seen) {
                    for (i = 1; i <= n; i++) hdr[cols[i]] = i
                    header_seen = 1
                    continue
                }
                if (cols[hdr["repeat_presence"]] != "TE") continue
                uid = cols[hdr["unique_insertion_id"]]
                ord = cols[hdr["Order"]]
                if (ord == "Penelope-like_Element") ord = "Retroelement"
                id_order[uid] = ord
                id_class[uid] = cols[hdr["Class"]]
            }
            close(repeat_tsv)
        }
        NR == 1 {
            print "ID","CHROM","BIN_START","BIN_END","WINDOW_SIZE","TE_BP","TE_FRACTION","N_TE","TE_PRESENT","ORDER","CLASS","FAMILY","MEAN_KIMURA_PERCENT","TE_IDS"
            next
        }
        {
            te_ids = $13
            if (te_ids == "NONE") {
                new_order = "NONE"; new_class = "NONE"
            } else {
                n = split(te_ids, ids, ";")
                new_order = ""; new_class = ""
                for (i = 1; i <= n; i++) {
                    id = ids[i]
                    o = (id in id_order) ? id_order[id] : "UNKNOWN"
                    c = (id in id_class) ? id_class[id] : "UNKNOWN"
                    if (new_order == "") new_order = o
                    else if (index(";" new_order ";", ";" o ";") == 0) new_order = new_order ";" o
                    if (new_class == "") new_class = c
                    else if (index(";" new_class ";", ";" c ";") == 0) new_class = new_class ";" c
                }
            }
            print $1, $2, $3, $4, $5, $6, $7, $8, $9, new_order, new_class, $11, $12, $13
        }
    ' "${old_annotation}" > "${new_annotation}"

    [[ -s "${new_annotation}" ]] || { echo "Failed to rebuild ${new_annotation}" >&2; exit 1; }

    # Join the corrected annotation columns back onto the existing VCFtools N_VARIANTS/N_MONOMORPHIC/PI values.
    awk -F '\t' -v OFS='\t' -v annfile="${new_annotation}" '
        BEGIN {
            row = 0
            while ((getline line < annfile) > 0) {
                row++
                if (row == 1) { header_ann = line; continue }
                split(line, f, "\t")
                key = f[2] FS f[3] FS f[4]
                ann[key] = line
            }
            close(annfile)
        }
        NR == 1 { print header_ann, "N_VARIANTS", "N_MONOMORPHIC", "PI"; next }
        {
            key = $2 FS $3 FS $4
            nvar = $14; nmono = $15; pi = $16
            if (key in ann) {
                print ann[key], nvar, nmono, pi
            } else {
                id = "VCFTOOLS_" $2 "_" $3 "_" $4
                print id, $2, $3, $4, $5, "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", nvar, nmono, pi
            }
        }
    ' "${old_pi}" > "${new_pi}"

    [[ -s "${new_pi}" ]] || { echo "Failed to rebuild ${new_pi}" >&2; exit 1; }

    cp "${old_annotation}" "${old_annotation}.bak"
    cp "${old_pi}" "${old_pi}.bak"
    mv "${new_annotation}" "${old_annotation}"
    mv "${new_pi}" "${old_pi}"
    echo "Reclassified ${old_annotation} and ${old_pi} ($(wc -l < "${old_pi}") lines); originals saved as *.bak"
done

head -n 1 genome_10kb_pi.tsv > fixed_windows_all_pi.tsv
tail -n +2 genome_5kb_pi.tsv >> fixed_windows_all_pi.tsv
tail -n +2 genome_10kb_pi.tsv >> fixed_windows_all_pi.tsv

echo "Rebuilt fixed_windows_all_pi.tsv ($(wc -l < fixed_windows_all_pi.tsv) lines)"

