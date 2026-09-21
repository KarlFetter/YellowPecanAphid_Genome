# Fixed Windows Approach

This directory contains a Bash-only fixed-window analysis of transposable elements (TEs) and genetic diversity in *Monelliopsis pecanis*.

## Runtime and inputs

Scripts are stored in Git under `Repeats/06_Repeats_Fixed_Windows`. Runtime files are written to SciNet:

`/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/fixed_windows_approach`

Inputs are:

- Genome: `/90daydata/tgl_seqdata/aphids/assembly/ypa/10_soft_masked_draft/ypa_primary_top6.fa`
- VCF: `/90daydata/tgl_seqdata/aphids/popgen/ypa/01_snps/ypa_DP10_220_biallelic_top6.vcf.gz`
- Repeat TSV: `/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/data/repeat_locations_types_k2_Complete_and_Fragmentary.tsv`

## Workflow

`01_make_fixed_windows.sh` loads `samtools` and `bedtools`, creates non-overlapping 5 kb and 10 kb windows, and annotates each window with TE overlap. The annotations include TE base pairs, TE fraction, TE presence, normalized `Order`, family, mean `Kimura_percent`, and overlapping `unique_insertion_id` values.

`02_calc_pi.sh` loads `vcftools/0.1.17` and runs `--window-pi` with a step equal to the window size. It joins the VCFtools results to the corresponding TE annotations using scaffold and window coordinates.

Run from the Git script directory on SciNet:

```bash
sbatch 01_make_fixed_windows.sh
sbatch 02_calc_pi.sh
```

## Outputs

Stage 1 creates `genome_5kb_windows.bed`, `genome_10kb_windows.bed`, `genome_5kb_te_annotations.tsv`, `genome_10kb_te_annotations.tsv`, and `te_intervals.bed`.

Stage 2 creates `genome_5kb.windowed.pi`, `genome_10kb.windowed.pi`, `genome_5kb_pi.tsv`, `genome_10kb_pi.tsv`, and `fixed_windows_all_pi.tsv`. Every row from each VCFtools `.windowed.pi` file is retained. Rows that do not exactly match a fixed-window annotation receive an ID beginning with `VCFTOOLS_` and `NA` TE annotation fields rather than being discarded.

BED coordinates are 0-based, half-open. VCFtools output coordinates are joined as 1-based window coordinates.

## Interpretation

The VCF contains SNPs from one unphased diploid individual. VCFtools can calculate a window statistic from this VCF, but the result is not population-level nucleotide diversity estimated from multiple individuals. Interpret `PI` as a single-individual, two-haplotype diversity measure and verify VCFtools behavior on a small test VCF before biological interpretation.

Q1 can use `TE_PRESENT` or `TE_FRACTION`; Q2 can use normalized `ORDER` and `FAMILY`; Q3 can use `MEAN_KIMURA_PERCENT`. Include scaffold/chromosome in downstream models because windows are spatially structured.

## Data dictionary

The annotation columns are produced from the repeat TSV and fixed genome windows. The VCFtools columns are appended by `02_calc_pi.sh`.

| Column | Description |
|---|---|
| `ID` | Stable fixed-window identifier: scaffold, 1-based start, and end. |
| `CHROM` | Reference scaffold or chromosome name. |
| `BIN_START` | 1-based inclusive window start. |
| `BIN_END` | 1-based inclusive window end. |
| `WINDOW_SIZE` | Requested window size in bp, either 5,000 or 10,000. The final scaffold window can be shorter. |
| `TE_BP` | Number of bases in the window overlapping annotated TE intervals. Overlapping TE records can cause this to count the same base more than once if annotations overlap. |
| `TE_FRACTION` | `TE_BP` divided by the actual window length. |
| `N_TE` | Number of TE annotation records overlapping the window. |
| `TE_PRESENT` | `TRUE` when at least one TE overlaps the window; otherwise `FALSE`. |
| `ORDER` | Normalized high-level TE order: `DNA_transposon`, `Retrotransposon`, `Rolling_Circle`, `Penelope_like_elements`, or `OTHER`. Multiple values are semicolon-separated. |
| `FAMILY` | Repeat family from `repeat_class.family`; multiple values are semicolon-separated. |
| `MEAN_KIMURA_PERCENT` | Mean `Kimura_percent` among overlapping TEs. `NA` means no TE age value is available, usually because the window has no TE. |
| `TE_IDS` | Semicolon-separated `unique_insertion_id` values for overlapping TEs. `NONE` means no TE overlaps. |
| `N_VARIANTS` | Number of variant records contributing to the VCFtools window. |
| `N_MONOMORPHIC` | Number of monomorphic sites counted by VCFtools in the window. |
| `PI` | VCFtools windowed nucleotide-diversity value. With one unphased diploid individual, interpret this as a single-individual/two-haplotype statistic, not population-level pi. |

The `.windowed.pi` files contain only windows for which VCFtools produced a result. They may not contain every fixed genome window, especially windows with no variant observations. `02_calc_pi.sh` retains every row VCFtools reports and adds `NA` annotation values if an exact fixed-window annotation match is unavailable.

## Q1 modeling framework

Q1 asks whether TE-associated windows differ in diversity from windows without TEs. Use the 10 kb table as the primary dataset and the 5 kb table as a sensitivity analysis.

The primary predictor is `TE_PRESENT`. The primary model is:

```text
log(PI) ~ TE_PRESENT + CHROM
```

This is a positive continuous model on the log scale. `CHROM` is treated as a fixed effect because there are only six chromosome-scale scaffolds and they are a defined part of the genome rather than a random sample of chromosomes. The coefficient for `TE_PRESENTTRUE` is interpreted as a multiplicative difference in PI: `exp(coefficient)` is the estimated PI ratio for TE-present versus TE-absent windows.

Run a separate secondary model using the continuous amount of TE sequence:

```text
log(PI) ~ TE_FRACTION + CHROM
```

Do not put `TE_PRESENT` and `TE_FRACTION` into the primary Q1 model together without a specific reason, because TE presence is directly derived from positive TE fraction. Do not use `N_VARIANTS` or `N_MONOMORPHIC` as ordinary predictors of PI because they are components of, or closely tied to, the response calculation.

The six scaffolds and nearby windows create spatial dependence. The current brms script includes scaffold effects; a later sensitivity model should add within-scaffold spatial autocorrelation if diagnostics show residual spatial structure. Report posterior estimates, 95% credible intervals, the TE-present/absent PI ratio, and posterior probabilities for the direction of the effect.

## brms models

The optional `03_fit_fixed_windows_brms.R` script fits separate lognormal models to the 10 kb data. Q1 tests `TE_PRESENT`, Q2 tests `ORDER` among TE-containing windows while adjusting for `TE_FRACTION`, and Q3 tests scaled `MEAN_KIMURA_PERCENT` among TE-containing windows while adjusting for `TE_FRACTION`. Each model includes scaffold fixed effects. A lognormal model is used because the VCFtools output is positive and is analyzed on the log scale; a hurdle model should only be used if a deliberately constructed dataset includes true zero-diversity windows.

Run it on SciNet in an R environment containing `brms`:

```bash
Rscript 03_fit_fixed_windows_brms.R
```

The model files and `sessionInfo.txt` are written to `brms_models/` under the runtime directory.