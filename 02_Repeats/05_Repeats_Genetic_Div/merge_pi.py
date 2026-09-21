#!/usr/bin/env python3
"""Normalize pixy interval output and merge it with interval metadata."""
import argparse
import csv
from pathlib import Path

HEADER = ["ID", "CHROM", "BIN_START", "BIN_END", "N_VARIANTS", "N_MONOMORPHIC", "PI", "CLASS"]
SPECS = [
    ("te_genomic_pi.txt", "te_genomic.bed", "te_genomic_pi.tsv"),
    ("left_flank_5kb_pi.txt", "left_flank_5kb.bed", "left_flank_5kb_pi.tsv"),
    ("right_flank_5kb_pi.txt", "right_flank_5kb.bed", "right_flank_5kb_pi.tsv"),
    ("non_TE_5kb_pi.txt", "non_TE_5kb_windows.bed", "non_TE_5kb_pi.tsv"),
    ("non_TE_10kb_pi.txt", "non_TE_10kb_windows.bed", "non_TE_10kb_pi.tsv"),
]


def find(row, names):
    for name in names:
        if name in row:
            return row[name]
    raise RuntimeError(f"pixy output is missing one of: {', '.join(names)}")


def read_bed(path):
    intervals = {}
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            fields = line.rstrip("\n").split("\t")
            if len(fields) >= 5:
                intervals[(fields[0], int(fields[1]) + 1, int(fields[2])] = (fields[3], fields[4])
    return intervals


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--workdir", required=True)
    args = parser.parse_args()
    workdir = Path(args.workdir)
    all_rows = []
    for pixy_name, bed_name, output_name in SPECS:
        pixy_path = workdir / pixy_name
        bed = read_bed(workdir / bed_name)
        rows = []
        with open(pixy_path, encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle, delimiter="\t")
            for raw in reader:
                chrom = find(raw, ["chromosome", "CHROM", "chrom"])
                start = int(find(raw, ["window_pos_1", "BIN_START", "start"]))
                end = int(find(raw, ["window_pos_2", "BIN_END", "end"]))
                key = (chrom, start, end)
                if key not in bed:
                    raise RuntimeError(f"Could not match pixy interval {key} to {bed_name}")
                interval_id, cls = bed[key]
                row = [interval_id, chrom, str(start), str(end),
                       find(raw, ["count_diffs", "N_VARIANTS", "n_variants"]),
                       find(raw, ["count_monomorphic", "count_missing", "N_MONOMORPHIC", "n_monomorphic"]),
                       find(raw, ["avg_pi", "PI", "pi"]), cls]
                rows.append(row)
                all_rows.append(row)
        with open(workdir / output_name, "w", encoding="utf-8", newline="") as handle:
            handle.write("\t".join(HEADER) + "\n")
            for row in rows:
                handle.write("\t".join(row) + "\n")

    with open(workdir / "te_genetic_diversity_all_regions.tsv", "w", encoding="utf-8", newline="") as handle:
        handle.write("\t".join(HEADER) + "\n")
        for row in all_rows:
            handle.write("\t".join(row) + "\n")
    print(f"Merged {len(all_rows)} pixy intervals")


if __name__ == "__main__":
    main()