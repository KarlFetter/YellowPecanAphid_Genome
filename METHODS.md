# Genome Assembly Methods — *Monelliopsis pecanis* (Yellow Pecan Aphid)

**For inclusion in manuscript. All citations marked [CITE] should be replaced with appropriate references.**

---

## 2. Materials and Methods

### 2.X Genome sequencing

Genomic DNA was extracted from [PLACEHOLDER — describe source colony/individuals] and sequenced using two long-read platforms. High-fidelity (HiFi) reads were generated on a PacBio Revio instrument using the PacBio Vega library preparation workflow. Reads were delivered as a single HiFi BAM file and converted to compressed FASTQ format using SAMtools v[PLACEHOLDER] [CITE: Li et al. 2009]. Oxford Nanopore Technologies (ONT) ultra-long reads were generated on a PromethION instrument; the *M. pecanis* library was multiplexed with two other aphid species and base-called reads for barcode03 were concatenated into a single FASTQ file using SeqKit [CITE: Shen et al. 2016]. Read quality statistics (total bases, read count, N50 read length) for both libraries were computed with SeqKit `stats`.

### 2.X Genome size estimation

Genome size was estimated by k-mer frequency analysis of the HiFi reads prior to assembly. Canonical 21-mers were counted with Jellyfish v2.2.9 [CITE: Marçais & Kingsford 2011] using a hash size of 10 GB and eight threads. The resulting k-mer frequency histogram was analyzed with GenomeScope2 [CITE: Ranallo-Benavidez et al. 2020] to estimate genome size, heterozygosity, and ploidy.

### 2.X De novo genome assembly

Multiple assembly strategies were evaluated to identify the most contiguous and complete assembly for *M. pecanis*. All assemblies were performed with hifiasm v0.25.0 [CITE: Cheng et al. 2021, 2022] or Verkko [CITE: Rautiainen et al. 2023] on the USDA SCINet Ceres HPC cluster using 64 threads. The following assemblies were generated: (1) a HiFi-only assembly (`hifiasm`, default parameters); (2) a HiFi + ONT ultra-long assembly using raw barcode reads passed directly via `--ul`; (3) a HiFi + ONT ultra-long assembly using length-filtered ONT reads (N50 ≈ 34 kb) via `--ul`; (4) an ONT-only assembly using `hifiasm --ont`; and (5) a HiFi + ONT assembly with Verkko. For hifiasm runs, the primary contig set (`*.bp.p_ctg.gfa`) and both haplotype-resolved contig sets (`*.bp.hap1.p_ctg.gfa`, `*.bp.hap2.p_ctg.gfa`) were extracted from GFA format to FASTA using `awk`. The completeness of each assembly was assessed using BUSCO v5 [CITE: Manni et al. 2021] in genome mode against the `insecta_odb10` lineage dataset. The hifiasm HiFi + ONT ultra-long assembly (filtered reads, N50 ≈ 34 kb) produced the most contiguous result and was selected for downstream processing.

### 2.X Haplotig purging

Duplicated sequences arising from heterozygous regions assembled into both haplotypes were identified and removed using purge_dups [CITE: Guan et al. 2020]. Briefly, HiFi reads were aligned to the primary contig assembly with `minimap2 -xmap-hifi` [CITE: Li 2018]. Per-base and per-read coverage statistics were computed with `pbcstat`, and low/mid/high coverage thresholds were derived automatically with `calcuts`. The assembly was split at N-gap regions with `split_fa`, then aligned to itself with `minimap2 -xasm5 -DP` to identify overlapping contig pairs. Duplicated regions were classified with `purge_dups -2` using the coverage thresholds and self-alignment overlaps, and the purged primary assembly (`purged.fa`) was extracted with `get_seqs`. The pipeline was applied independently to haplotype 1 and haplotype 2 contig sets.

### 2.X Scaffolding and gap-filling

Purged contigs were scaffolded and gap-filled using SAMBA (Simple Assembly Merging and Building Algorithm) from the MaSuRCA v4.1.0 package [CITE: Zimin et al. 2013; Zimin & Salzberg 2022]. SAMBA was run in HiFi assembly mode (`-d asm`) with a minimum match length of 2,500 bp (`-m 2500`), which is appropriate for the compact genome sizes typical of aphids (~300–500 Mb) [CITE: where you cite aphid genome sizes]. Unlike gap-filling approaches that insert N-pads, SAMBA fills gaps with real sequence from the HiFi reads, increasing contig lengths and assembly contiguity. Scaffolding was performed on hap1 and hap2 purged contig sets using the raw HiFi reads.

### 2.X Contamination screening

Scaffolded assemblies were screened for foreign sequence contamination using two independent methods. First, BlobToolKit [CITE: Challis et al. 2020] was used to visualize per-contig GC content, read coverage, and taxonomic assignment. HiFi reads were aligned to the scaffolded primary assembly with `minimap2 -ax map-hifi`, and the sorted BAM provided per-contig read depth. Contigs with anomalous coverage or GC content, including those from bacterial endosymbionts (e.g., *Buchnera aphidicola*, which is expected in aphid genomes at high coverage relative to nuclear sequences) were identified and flagged. Second, NCBI FCS-GX [CITE: Astashyn et al. 2024] was run via Apptainer against the full NCBI FCS-GX database (≈470 GB) to screen for foreign contamination against the NCBI taxonomy. Screens were run independently for the primary, hap1, and hap2 assemblies using NCBI Taxon ID 2982816 (*Monelliopsis pecanis*). Flagged sequences were removed or trimmed using `gx clean-genome`, and the cleaned assemblies were used for all downstream analyses.

### 2.X Assembly quality assessment

Final cleaned assemblies were assessed for completeness and contiguity. Gene space completeness was evaluated with BUSCO v5 against the `insecta_odb10` lineage dataset in genome mode. Contiguity statistics (total assembly length, number of scaffolds, N50, L50, largest scaffold) were computed with QUAST [CITE: Gurevich et al. 2013]. Sequencing coverage was estimated as total read bases divided by assembly size (theoretical coverage) and confirmed empirically by mapping HiFi and ONT reads with `minimap2` (map-hifi and map-ont modes, respectively) and computing genome-wide depth and breadth of coverage with `samtools coverage` [CITE: Li et al. 2009]. Genome-wide coverage uniformity was examined in 100-kb non-overlapping windows using `bedtools makewindows` and `bedtools coverage -mean` [CITE: Quinlan & Hall 2010].

*M. pecanis* has a haploid chromosome number of n = 6 [PLACEHOLDER — confirm chromosome number from literature]. The six largest scaffolds in the final primary assembly were extracted as putative chromosomal sequences using `seqkit sort --by-length --reverse | seqkit head -n 6`. A HISAT2 [CITE: Kim et al. 2019] index was constructed from the final chromosome-scale primary assembly to support downstream RNA-seq alignment for gene annotation.

---

## Suggested Citations

> Astashyn, A. *et al.* (2024). Rapid and sensitive detection of genome contamination at scale with FCS-GX. *Genome Biology*, 25, 60.

> Challis, R. *et al.* (2020). BlobToolKit – Interactive Quality Assessment of Genome Assemblies. *G3: Genes, Genomes, Genetics*, 10(4), 1361–1374.

> Cheng, H. *et al.* (2021). Haplotype-resolved de novo assembly using phased assembly graphs with hifiasm. *Nature Methods*, 18, 170–175.

> Cheng, H. *et al.* (2022). Trio-hifiasm: haplotype-aware genome assembly. *Nature Biotechnology*, 40, 679–686.

> Guan, D. *et al.* (2020). Identifying and removing haplotypic duplication in primary genome assemblies. *Bioinformatics*, 36(9), 2896–2898.

> Gurevich, A. *et al.* (2013). QUAST: quality assessment tool for genome assemblies. *Bioinformatics*, 29(8), 1072–1075.

> Kim, D., Paggi, J.M., Park, C. *et al.* (2019). Graph-based genome alignment and genotyping with HISAT2 and HISAT-genotype. *Nature Biotechnology*, 37, 907–915.

> Li, H. (2018). Minimap2: pairwise alignment for nucleotide sequences. *Bioinformatics*, 34(18), 3094–3100.

> Li, H. *et al.* (2009). The Sequence Alignment/Map format and SAMtools. *Bioinformatics*, 25(16), 2078–2079.

> Manni, M. *et al.* (2021). BUSCO Update: Novel and Streamlined Workflows along with Broader and Deeper Phylogenetic Coverage for Scoring of Eukaryotic, Prokaryotic, and Viral Genomes. *Molecular Biology and Evolution*, 38(10), 4647–4654.

> Marçais, G. & Kingsford, C. (2011). A fast, lock-free approach for efficient parallel counting of occurrences of k-mers. *Bioinformatics*, 27(6), 764–770.

> Quinlan, A.R. & Hall, I.M. (2010). BEDTools: a flexible suite of utilities for comparing genomic features. *Bioinformatics*, 26(6), 841–842.

> Ranallo-Benavidez, T.R. *et al.* (2020). GenomeScope 2.0 and Smudgeplots for reference-free profiling of polyploid genomes. *Nature Communications*, 11, 1432.

> Rautiainen, M. *et al.* (2023). Telomere-to-telomere assembly of diploid chromosomes with Verkko. *Nature Biotechnology*, 41, 1474–1482.

> Shen, W. *et al.* (2016). SeqKit: A Cross-Platform and Ultrafast Toolkit for FASTA/Q File Manipulation. *PLOS ONE*, 11(10), e0163962.

> Zimin, A.V. *et al.* (2013). The MaSuRCA genome assembler. *Bioinformatics*, 29(21), 2669–2677.

> Zimin, A.V. & Salzberg, S.L. (2022). The genome polishing tool POLCA makes fast and accurate corrections in genome assemblies. *PLOS Computational Biology*, 18(6), e1010061.
