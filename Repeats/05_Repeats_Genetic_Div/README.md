# TE Genetic Diversity Workflow

This workflow creates TE-associated and random non-TE intervals, calculates nucleotide diversity with pixy, and merges the outputs into one table for Q1-Q3.

## Run location

The scripts are stored in Git under `Repeats/05_Repeats_Genetic_Div/`. Runtime files are written to:

`/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/data`

The input repeat TSV must be present in that runtime directory. The genome and VCF use the fixed paths in the scripts.

## Commands

Run the stages in order from the script directory:

```bash
sbatch 01_make_windows.sh
sbatch 02_calc_pi.sh
sbatch 03_merge_pi.sh
```

Submit stage 2 only after stage 1 has completed successfully. Confirm the installed pixy version and `pixy --help` syntax on Ceres before the first production run.

## Outputs

The interval stage writes `te_genomic.bed`, `left_flank_5kb.bed`, `right_flank_5kb.bed`, `non_TE_5kb_windows.bed`, and `non_TE_10kb_windows.bed`, plus interval metadata, the pixy population file, and filtering audit information.

The pixy and merge stages write `te_genomic_pi.tsv`, `left_flank_5kb_pi.tsv`, `right_flank_5kb_pi.tsv`, `non_TE_5kb_pi.tsv`, `non_TE_10kb_pi.tsv`, and `te_genetic_diversity_all_regions.tsv`.

TE coordinates are converted from 1-based inclusive repeat-table coordinates to 0-based half-open BED coordinates. Complete 5 kb flanks are required. Overlapping TE-genomic intervals are dropped deterministically. Non-TE windows are 1 Mb from scaffold ends, TE-free relative to retained TE-genomic regions, mutually non-overlapping, and sampled with a fixed seed.