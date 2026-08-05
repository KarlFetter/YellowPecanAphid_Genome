# Genome Assembly Pipeline — *Monellia caryella* (Yellow Pecan Aphid)

This document describes the complete genome assembly pipeline used to generate a chromosome-scale draft assembly of the yellow pecan aphid, *Monellia caryella*, from PacBio HiFi and Oxford Nanopore Technologies (ONT) long reads. All scripts are organized by pipeline step and were run on the USDA SCINet Ceres HPC cluster using SLURM.

---

## Pipeline Overview

```
01_raw_reads/           Convert HiFi BAM → FASTQ; concatenate and QC ONT reads
03_genome_size/         k-mer counting (Jellyfish) → GenomeScope2 genome size estimate
04_assembly/            De novo assembly (hifiasm, Verkko); GFA → FASTA; BUSCO QC
05_purge_haplotigs/     Haplotig purging (purge_dups) for hap1 and hap2
06_scaffolding/         Scaffold and gap-fill purged contigs (SAMBA / MaSuRCA)
07_contam_filter/       Contamination screening (BlobToolKit, NCBI FCS-GX)
08_final_draft_assembly/Assembly QC: BUSCO, QUAST, coverage statistics
09_coverage/            Genome-wide windowed coverage (100 kb windows)
10_soft_masked_draft/   Chromosome extraction, HISAT2 index
```

---

## Step 1 — Raw Read Processing (`01_raw_reads/`)

### HiFi reads

PacBio HiFi reads were delivered as a single BAM file from the sequencing instrument. The BAM was converted to compressed FASTQ using `samtools fastq`, and basic read statistics (read count, total bases, N50) were calculated with `seqkit stats`.

| Script | Purpose |
|---|---|
| `bam2fastq.sh` | `samtools fastq` BAM → gzipped FASTQ |
| `seqkit_stats.sh` | Read statistics across all FASTQ files |

**Key parameters**: 8 threads, `samtools fastq`; `seqkit stats -a`

### ONT reads

Oxford Nanopore PromethION reads for *M. caryella* were multiplexed with other aphid species and demultiplexed to barcode03. Individual pass-filter FASTQ files were concatenated with `seqkit seq` and per-file and aggregate statistics were computed. A read-length histogram was generated for QC.

| Script | Purpose |
|---|---|
| `cat.sh` | Concatenate barcode03 FASTQ files with `seqkit seq` |
| `ont_stats.sh` | Per-file ONT read statistics |
| `ont_stats2.sh` | Aggregate ONT statistics and coverage estimate |
| `seq_length_histo.sh` | Read-length histogram (seqkit + Python) |

---

## Step 2 — Genome Size Estimation (`03_genome_size/`)

Genome size was estimated by k-mer frequency analysis of the HiFi reads.

| Script | Purpose |
|---|---|
| `01_jellyfish_genome_size.sh` | k-mer counting and histogram generation |

**Workflow**:
1. **Jellyfish v2.2.9** counted canonical 21-mers (`jellyfish count -m 21 -C`) from the HiFi FASTQ.
2. A k-mer frequency histogram was generated (`jellyfish histo`).
3. The histogram was uploaded to **GenomeScope2** (http://qb.cshl.edu/genomescope/genomescope2.0/) to estimate genome size, heterozygosity, and ploidy.

**Key parameters**: k = 21, hash size = 10G, 8 threads, canonical counting (`-C`)

---

## Step 3 — De Novo Genome Assembly (`04_assembly/`)

Multiple assemblies were generated to compare assemblers and input read combinations. Each assembly was evaluated with BUSCO before selecting the best candidate for downstream processing.

### Assembly strategies

| Script | Assembler | Read input | Notes |
|---|---|---|---|
| `01_hifiasm.sh` | hifiasm v0.25.0 | HiFi only | Baseline HiFi assembly |
| `01b_hifiasm_ul_barcodeONTreads.sh` | hifiasm v0.25.0 | HiFi + ONT (raw barcode files, `--ul`) | ONT reads passed directly from barcode directory |
| `01d_hifiasm_ul_34KbN50.sh` | hifiasm v0.25.0 | HiFi + ONT (filtered, N50 ~34 kb, `--ul`) | Ultra-long mode with length-filtered ONT reads |
| `01c_ont_hifiasm.sh` | hifiasm v0.25.0 | ONT simplex only (`--ont`) | ONT-only assembly for comparison |
| `verkko.sh` | Verkko | HiFi + ONT | Graph-based assembler as an alternative |

**hifiasm parameters (all runs)**: 64 threads, default error correction and graph parameters; `--ul` flag for ultra-long ONT-assisted assembly.

### GFA to FASTA conversion

hifiasm outputs assemblies in GFA format. Primary contigs and haplotype-resolved contigs were converted to FASTA with `awk`:

```bash
awk '/^S/{print ">"$2; print $3}' assembly.gfa | gzip -c > assembly.fa.gz
```

Each assembly directory (`hifiasm/`, `hifiasm_ul_34kbN50/`, `hifiasm_ul_ONTbarcodeReads/`, `ont_hifiasm/`) contains:

| Script | Purpose |
|---|---|
| `gfa2fasta.sh` | Convert GFA → gzipped FASTA for primary, hap1, hap2 |
| `busco_insecta.sh` | BUSCO v5 assessment (insecta_odb10) of all three outputs |

### Assembly quality assessment

BUSCO v5 was run against the `insecta_odb10` lineage dataset in genome mode for the primary contig set (`*.bp.p_ctg.fa`), haplotype 1 (`*.bp.hap1.p_ctg.fa`), and haplotype 2 (`*.bp.hap2.p_ctg.fa`) of each assembly. The hifiasm HiFi+ONT ultra-long assembly (`hifiasm_ul_34kbN50`) produced the most contiguous result and was selected for downstream processing.

---

## Step 4 — Haplotig Purging (`05_purge_haplotigs/`)

Haplotype-resolved assemblies from hifiasm may retain duplicated sequences where both haplotypes assemble into the primary contig set. Haplotigs were removed using the **purge_dups** pipeline.

| Script | Assembly input |
|---|---|
| `05_purge_haplotig_pipeline.sh` | hifiasm hap1 primary contigs |
| `05b_purge_haplotig_pipeline.sh` | hifiasm_ul_34kbN50 hap2 primary contigs |

**Three-step pipeline**:

1. **Step 1 — Read alignment**: HiFi reads were aligned to the primary contig assembly with `minimap2 -xmap-hifi` and output as a gzipped PAF file.
2. **Step 2 — Coverage statistics and self-alignment**:
   - `pbcstat` computed per-base (`PB.base.cov`) and per-read (`PB.stat`) coverage from the PAF.
   - `calcuts` automatically determined low, mid, and high coverage thresholds.
   - `split_fa` split the assembly at N-gaps to prevent self-alignments spanning gaps.
   - `minimap2 -xasm5 -DP` performed self-alignment of the split assembly to identify overlapping duplicated contigs.
3. **Step 3 — Purging**:
   - `purge_dups -2 -T cutoffs -c PB.base.cov` classified contig regions as haplotigs, overlaps, or retained sequence.
   - `get_seqs` extracted the purged primary assembly (`purged.fa`) and removed haplotigs (`hap.fa`).
   - `seqkit stats -a` reported QC statistics on both outputs.

**Key parameters**: 32 threads, minimap2 `-xmap-hifi` for read mapping, `-xasm5 -DP` for self-alignment.

---

## Step 5 — Scaffolding (`06_scaffolding/`)

Purged primary contigs were scaffolded using **SAMBA** (from the MaSuRCA v4.1.0 package), which uses HiFi reads to both order/orient contigs and fill gaps with real sequence (rather than N-pads).

| Script | Assembly input |
|---|---|
| `06a_samba_scaffold.sh` | hifiasm hap2 purged contigs |
| `06b_samba_scaffold.sh` | hifiasm_ul_34kbN50 hap2 purged contigs |

**SAMBA parameters**:
- `-d asm` — data type: PacBio HiFi assembly mode
- `-m 2500` — minimum matching length (2,500 bp; appropriate for aphid genome sizes of ~300–500 Mb)
- `-t 32` — threads

Output: `purged.fa.scaffolds.fa` — scaffolded and gap-filled assembly.

---

## Step 6 — Contamination Filtering (`07_contam_filter/`)

Assemblies were screened for foreign sequence contamination using two independent approaches.

### BlobToolKit (`blobtoolkit/`)

| Script | Purpose |
|---|---|
| `01_map_reads.sh` | Map HiFi reads to assembly for per-contig coverage |

HiFi reads were aligned to the scaffolded primary assembly with `minimap2 -ax map-hifi`, and the output was sorted and indexed with `samtools sort` and `samtools index`. The resulting BAM provides per-contig read depth — one of three signals used in BlobToolKit (along with GC content and BLAST/Diamond taxonomic hits) to identify contaminant sequences. Contaminant contigs (e.g., bacterial endosymbiont *Buchnera aphidicola* at anomalously high coverage, or low-coverage foreign contigs) were identified visually using BlobToolKit plots.

**Key parameters**: 32 threads, `minimap2 -ax map-hifi`, `samtools sort -m 4G`

### NCBI FCS-GX (`fcs_gx/`)

| Script | Purpose |
|---|---|
| `01_fcs_gx_screen.sh` / `01_fcs_gx_screen_echo.sh` | Screen assembly for foreign contamination |
| `02_apply_fcs_filter.sh` | Apply FCS-GX action report to clean assembly |

NCBI's Foreign Contamination Screen (FCS-GX) was run via Apptainer/Singularity using the FCS-GX database (≈470 GB loaded into memory). The tool assigns each scaffold a taxonomic label and flags sequences inconsistent with the target organism. Contamination reports were generated for the primary, hap1, and hap2 assemblies independently.

The `gx clean-genome` command applied the action report to remove or trim flagged sequences, producing the cleaned FASTA files used for all downstream analyses.

**Key parameters**: NCBI Taxon ID 527790 (*Monellia caryella*), FCS-GX database at `/project/tgl_seqdata/databases/fcs-gx/gxdb`, 500 GB memory

---

## Step 7 — Final Draft Assembly QC (`08_final_draft_assembly/`)

The contamination-cleaned assemblies (primary, hap1, hap2) were evaluated for completeness, contiguity, and sequencing coverage.

| Script | Purpose |
|---|---|
| `busco_insecta.sh` | BUSCO v5 completeness (insecta_odb10) |
| `quast.sh` | Assembly contiguity statistics (QUAST) |
| `coverage_multi.sh` | Theoretical HiFi and ONT coverage (seqkit) |
| `empirical_coverage.sh` | Empirical mapped coverage (minimap2 + samtools) |
| `index_multi.sh` | Index assemblies (samtools faidx, minimap2 .mmi) |
| `filter4chrom.sh` | Extract top 6 scaffolds (putative chromosomes) |

**BUSCO**: run against `insecta_odb10` lineage in genome mode, offline (`--offline`), 16 threads.

**QUAST**: basic assembly statistics (contig N50, L50, total length, number of contigs).

**Coverage**: theoretical coverage was calculated as total read bases / assembly size. Empirical depth and breadth were calculated by mapping HiFi reads with `minimap2 -ax map-hifi` and ONT reads with `minimap2 -ax map-ont` to each assembly, sorting with `samtools sort`, and calculating per-reference-sequence depth and breadth with `samtools coverage`. Results were summarized across all scaffolds for a genome-wide estimate.

**Chromosome extraction**: *M. caryella* has 2n = 12 chromosomes (6 pairs). The six largest scaffolds were extracted as putative chromosome-scale sequences using `seqkit sort --by-length --reverse | seqkit head -n 6`.

---

## Step 8 — Genome-Wide Coverage (`09_coverage/`)

| Script | Purpose |
|---|---|
| `map_and_window_coverage.sh` | 100-kb windowed HiFi and ONT coverage across all assemblies |

For each cleaned assembly, HiFi and ONT reads were independently aligned with `minimap2` (map-hifi and map-ont modes). Alignments were sorted, indexed, and coverage was computed in 100-kb non-overlapping windows using `bedtools makewindows` and `bedtools coverage -mean`. Output BED files were used for genome-wide coverage visualization.

**Key parameters**: 16 threads, 100,000-bp windows, `samtools sort -m 6G`

---

## Step 9 — Soft-Masked Draft Preparation (`10_soft_masked_draft/`)

| Script | Purpose |
|---|---|
| `filter_bam_to_chrs.sh` | Subset alignment BAM to the 6 chromosomal scaffolds |
| `hisat2-build.sh` | Build HISAT2 splice-aware index for RNA-seq alignment |

The six chromosomal scaffolds were extracted from the genome-wide coverage BAM (`samtools view -b`) and re-indexed. A HISAT2 index (`hisat2-build -p 8`) was built from the primary chromosome-scale FASTA to support downstream RNA-seq mapping for gene annotation.

---

## Software Versions

| Tool | Version | Use |
|---|---|---|
| samtools | — | BAM/FASTQ conversion, sorting, indexing, coverage |
| seqkit | — | Read and assembly statistics |
| Jellyfish | 2.2.9 | k-mer counting |
| hifiasm | 0.25.0 | De novo genome assembly |
| Verkko | — | Alternative graph-based assembler |
| BUSCO | 5 | Assembly completeness assessment |
| purge_dups | — | Haplotig identification and removal |
| minimap2 | — | Read alignment, self-alignment |
| MaSuRCA / SAMBA | 4.1.0 | Scaffolding and gap-filling |
| BlobToolKit | — | Coverage-based contamination visualization |
| NCBI FCS-GX | — | Contamination screening |
| QUAST | — | Assembly contiguity statistics |
| bedtools | — | Windowed coverage analysis |
| HISAT2 | — | Splice-aware RNA-seq aligner index |

---

## HPC Environment

All jobs were submitted to the **USDA SCINet Ceres HPC cluster** via SLURM. Modules were loaded via `module load`. Large-memory steps (genome assembly, FCS-GX) required up to 750 GB RAM. Storage of intermediate files used the `/90daydata/` scratch filesystem.

---

## See Also

- [Main README](../README.md)
- [METHODS.md](../METHODS.md) — Manuscript methods section
