#!/usr/bin/env python3
"""Create TE/flank and reproducible non-TE intervals for the pixy stage."""
import argparse
import csv
import gzip
import bisect
import random
from pathlib import Path


REQUIRED = {
    "query_seq", "pos_query_begin", "pos_query_end", "Order",
    "repeat_class.family", "Kimura_percent", "unique_insertion_id",
    "repeat_presence",
}


def read_fai(path):
    lengths = {}
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            fields = line.rstrip("\n").split("\t")
            if len(fields) >= 2:
                lengths[fields[0]] = int(fields[1])
    return lengths


def write_bed(path, rows):
    with open(path, "w", encoding="utf-8", newline="") as handle:
        for row in rows:
            handle.write("\t".join(str(value) for value in row) + "\n")


def overlaps(a, b):
    return a[0] == b[0] and a[1] < b[2] and b[1] < a[2]


def choose_nonoverlapping(candidates, count, seed):
    rng = random.Random(seed)
    shuffled = list(candidates)
    rng.shuffle(shuffled)
    selected = []
    by_chrom = {}
    for candidate in shuffled:
        chrom, start, end = candidate[:3]
        if any(start < old_end and old_start < end
               for old_start, old_end in by_chrom.get(chrom, [])):
            continue
        selected.append(candidate)
        by_chrom.setdefault(chrom, []).append((start, end))
        if len(selected) == count:
            return selected
    raise RuntimeError(f"Only {len(selected)} valid non-TE windows available; need {count}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--genome", required=True)
    parser.add_argument("--fai", required=True)
    parser.add_argument("--repeats", required=True)
    parser.add_argument("--vcf", required=True)
    parser.add_argument("--outdir", required=True)
    parser.add_argument("--seed", type=int, required=True)
    args = parser.parse_args()
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    with gzip.open(args.vcf, "rt", encoding="utf-8") if args.vcf.endswith(".gz") else open(args.vcf, encoding="utf-8") as handle:
        for line in handle:
            if line.startswith("#CHROM"):
                samples = line.rstrip("\n").split("\t")[9:]
                if len(samples) < 2:
                    raise RuntimeError("VCF must contain at least two samples for pi")
                with open(outdir / "pixy_populations.tsv", "w", encoding="utf-8") as populations:
                    for sample in samples:
                        populations.write(f"{sample}\tYPA\n")
                break
        else:
            raise RuntimeError("Could not find VCF #CHROM header")
    lengths = read_fai(args.fai)
    audit = []
    te = []
    seen = set()
    with open(args.repeats, encoding="utf-8", newline="") as handle:
        reader = csv.DictReader((line for line in handle if not line.startswith("#")), delimiter="\t")
        missing = REQUIRED - set(reader.fieldnames or [])
        if missing:
            raise RuntimeError(f"Missing repeat columns: {', '.join(sorted(missing))}")
        for row in reader:
            if row["repeat_presence"] != "TE":
                continue
            uid = row["unique_insertion_id"]
            if uid in seen:
                raise RuntimeError(f"Duplicate unique_insertion_id: {uid}")
            seen.add(uid)
            chrom = row["query_seq"]
            start = int(row["pos_query_begin"]) - 1
            end = int(row["pos_query_end"])
            if chrom not in lengths or start < 0 or end <= start or end > lengths[chrom]:
                audit.append((uid, "invalid_interval"))
                continue
            left = (chrom, start - 5000, start)
            right = (chrom, end, end + 5000)
            genomic = (chrom, start - 5000, end + 5000)
            if left[1] < 0 or right[2] > lengths[chrom]:
                audit.append((uid, "scaffold_edge"))
                continue
            te.append({"row": row, "uid": uid, "left": left, "right": right, "genomic": genomic})

    retained = []
    occupied = {}
    for item in sorted(te, key=lambda x: (x["genomic"][0], x["genomic"][1], x["uid"])):
        interval = item["genomic"]
        if any(interval[1] < old_end and old_start < interval[2]
               for old_start, old_end, _ in occupied.get(interval[0], [])):
            audit.append((item["uid"], "overlapping_te_genomic_window"))
            continue
        retained.append(item)
        occupied.setdefault(interval[0], []).append((interval[1], interval[2], item["uid"]))

    metadata_header = ["ID", "CHROM", "START0", "END0", "unique_insertion_id", "Order", "family", "Kimura_percent", "CLASS"]
    outputs = {"left_flank_5kb.bed": [], "right_flank_5kb.bed": [], "te_genomic.bed": []}
    metadata = []
    for item in retained:
        row = item["row"]
        for name, interval, cls in [
            ("left_flank_5kb.bed", item["left"], "FLANK_LEFT"),
            ("right_flank_5kb.bed", item["right"], "FLANK_RIGHT"),
            ("te_genomic.bed", item["genomic"], "TE_GENOMIC"),
        ]:
            outputs[name].append((interval[0], interval[1], interval[2], item["uid"], cls))
            metadata.append([item["uid"], interval[0], interval[1], interval[2], item["uid"], row["Order"], row["repeat_class.family"], row["Kimura_percent"], cls])

    for name, rows in outputs.items():
        write_bed(outdir / name, rows)
    with open(outdir / "te_interval_metadata.tsv", "w", encoding="utf-8", newline="") as handle:
        handle.write("\t".join(metadata_header) + "\n")
        for row in metadata:
            handle.write("\t".join(row) + "\n")

    mask_by_chrom = {}
    for item in retained:
        chrom, start, end = item["genomic"]
        mask_by_chrom.setdefault(chrom, []).append((start, end))
    for chrom in mask_by_chrom:
        mask_by_chrom[chrom].sort()

    def overlaps_mask(chrom, start, end):
        intervals = mask_by_chrom.get(chrom, [])
        position = bisect.bisect_left(intervals, (start, start))
        for mask_start, mask_end in intervals[max(0, position - 1):position + 1]:
            if start < mask_end and mask_start < end:
                return True
        return False

    for size, label in [(5000, "5KB"), (10000, "10KB")]:
        candidates = []
        for chrom, length in lengths.items():
            for start in range(1_000_000, length - 1_000_000 - size + 1, size):
                end = start + size
                if overlaps_mask(chrom, start, end):
                    continue
                candidates.append((chrom, start, end))
        selected = choose_nonoverlapping(candidates, 2000, args.seed + size)
        rows = [(chrom, start, end, f"NONTE_{label}_{i:06d}", f"NON_TE_{label}") for i, (chrom, start, end) in enumerate(sorted(selected), 1)]
        write_bed(outdir / f"non_TE_{label.lower()}_windows.bed", rows)

    with open(outdir / "window_filter_audit.tsv", "w", encoding="utf-8") as handle:
        handle.write("unique_insertion_id\treason\n")
        for row in audit:
            handle.write("\t".join(row) + "\n")
    print(f"TE rows retained: {len(retained)}; filtered: {len(audit)}")


if __name__ == "__main__":
    main()