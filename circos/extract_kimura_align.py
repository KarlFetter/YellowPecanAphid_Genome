#!/usr/bin/env python3
"""Extract per-insertion Kimura values from a RepeatMasker .align file.
"""
import argparse
import re

HEADER = [
    "unique_insertion_id", "query_sequence", "position_begin", "position_end", "repeat_size", "strand",
    "matching_repeat", "repeat_family", "repeat_class", "repeat_order", "repeat_presence",
    "sw_score", "perc_div", "perc_del", "perc_ins", "id",
    "kimura_percent", "kimura_unadjusted", "cpg_sites",
]

KIMURA_RE = re.compile(r"Kimura \(with divCpGMod\)\s*=\s*([\d.]+)")
CPG_RE = re.compile(r"CpG sites\s*=\s*(\d+),\s*Kimura \(unadjusted\)\s*=\s*([\d.]+)")


def classify(repeat_family):
    # repeat_class is the RepeatMasker class code before "/"; repeat_order collapses
    # everything non-TE (Simple_repeat, Low_complexity, Satellite, Unknown) to "Unknown".
    repeat_class = repeat_family.split("/", 1)[0] if repeat_family else "Unknown"
    if repeat_class == "DNA":
        repeat_order = "DNA_transposon"
    elif repeat_class in ("LINE", "SINE", "LTR", "PLE"):
        repeat_order = "Retrotransposon"
    elif repeat_class == "RC":
        repeat_order = "Rolling_Circle"
    else:
        repeat_order = "Unknown"
    repeat_presence = "TE" if repeat_order != "Unknown" else "nonTE"
    return repeat_class, repeat_order, repeat_presence


def parse_header(line):
    tokens = line.split()
    if len(tokens) < 13 or not tokens[0].isdigit() or tokens[8] not in ("+", "C"):
        return None
    try:
        sw_score = int(tokens[0])
        perc_div, perc_del, perc_ins = float(tokens[1]), float(tokens[2]), float(tokens[3])
        pos_begin, pos_end = int(tokens[5]), int(tokens[6])
        rm_id = int(tokens[-1])
    except ValueError:
        return None

    query_seq = tokens[4]
    strand = tokens[8]
    matching_full = tokens[9]
    if "#" in matching_full:
        matching_repeat, repeat_family = matching_full.split("#", 1)
    else:
        matching_repeat, repeat_family = matching_full, "Unknown"
    repeat_class, repeat_order, repeat_presence = classify(repeat_family)

    return {
        "unique_insertion_id": f"{query_seq}_{pos_begin}_{repeat_family}",
        "query_sequence": query_seq,
        "position_begin": pos_begin,
        "position_end": pos_end,
        "repeat_size": pos_end - pos_begin + 1,
        "strand": strand,
        "matching_repeat": matching_repeat,
        "repeat_family": repeat_family,
        "repeat_class": repeat_class,
        "repeat_order": repeat_order,
        "repeat_presence": repeat_presence,
        "sw_score": sw_score,
        "perc_div": perc_div,
        "perc_del": perc_del,
        "perc_ins": perc_ins,
        "id": rm_id,
        "kimura_percent": None,
        "kimura_unadjusted": None,
        "cpg_sites": None,
    }


def parse_align(align_path):
    current = None
    with open(align_path, encoding="utf-8", errors="replace") as handle:
        for raw_line in handle:
            header = parse_header(raw_line)
            if header is not None:
                if current is not None:
                    yield current
                current = header
                continue
            if current is None:
                continue
            stripped = raw_line.strip()
            kimura_match = KIMURA_RE.search(stripped)
            if kimura_match:
                current["kimura_percent"] = float(kimura_match.group(1))
                continue
            cpg_match = CPG_RE.search(stripped)
            if cpg_match:
                current["cpg_sites"] = int(cpg_match.group(1))
                current["kimura_unadjusted"] = float(cpg_match.group(2))
                yield current
                current = None
    if current is not None:
        yield current


def format_value(value):
    return "NA" if value is None else str(value)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--align", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    n_records = 0
    n_missing_kimura = 0
    with open(args.out, "w", encoding="utf-8") as out_handle:
        out_handle.write("\t".join(HEADER) + "\n")
        for record in parse_align(args.align):
            n_records += 1
            if record["kimura_percent"] is None:
                n_missing_kimura += 1
            out_handle.write("\t".join(format_value(record[key]) for key in HEADER) + "\n")

    print(f"Wrote {n_records} records to {args.out}")
    print(f"Records missing a Kimura value: {n_missing_kimura}")


if __name__ == "__main__":
    main()
