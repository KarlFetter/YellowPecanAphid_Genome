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

Scaffolded assemblies were screened for foreign sequence contamination using NCBI FCS-GX [CITE: Astashyn et al. 2024], run via Apptainer against the full NCBI FCS-GX database (≈470 GB). Screens were run independently for the primary, hap1, and hap2 assemblies using NCBI Taxon ID 2982816 (*Monelliopsis pecanis*). Flagged sequences were removed or trimmed using `gx clean-genome`, and the cleaned assemblies were used for all downstream analyses.

### 2.X Assembly quality assessment

Final cleaned assemblies were assessed for completeness and contiguity. Gene space completeness was evaluated with BUSCO v5 against the `insecta_odb10` lineage dataset in genome mode. Contiguity statistics (total assembly length, number of scaffolds, N50, L50, largest scaffold) were computed with QUAST [CITE: Gurevich et al. 2013]. Sequencing coverage was estimated as total read bases divided by assembly size (theoretical coverage) and confirmed empirically by mapping HiFi and ONT reads with `minimap2` (map-hifi and map-ont modes, respectively) and computing genome-wide depth and breadth of coverage with `samtools coverage` [CITE: Li et al. 2009]. Genome-wide coverage uniformity was examined in 100-kb non-overlapping windows using `bedtools makewindows` and `bedtools coverage -mean` [CITE: Quinlan & Hall 2010].

*M. pecanis* has a haploid chromosome number of n = 6 [PLACEHOLDER — confirm chromosome number from literature]. The six largest scaffolds in the final primary assembly were extracted as putative chromosomal sequences using `seqkit sort --by-length --reverse | seqkit head -n 6`. A HISAT2 [CITE: Kim et al. 2019] index was constructed from the final chromosome-scale primary assembly to support downstream RNA-seq alignment for gene annotation.

### 2.X Repeat identification and masking

Repetitive elements were identified and soft-masked in the final primary assembly using a four-step pipeline. First, a species-specific repeat consensus library was generated with RepeatModeler2 [CITE: Flynn et al. 2020], using the structural `-LTRStruct` pipeline (LTRHarvest + LTR_retriever) to improve detection of full-length LTR retrotransposons. Second, the de novo library was curated with TEtrimmer [CITE: Qian et al. 2025], which re-aligns each consensus sequence to the genome to extend terminal repeat boundaries, removes redundant sequences, and classifies previously unclassified elements using Pfam domain signatures. Third, a unified repeat library was built by merging the curated *M. pecanis*-specific library with Insecta repeat families extracted from the RepeatMasker library (FamDB) and four taxonomically targeted RepBase v31.07 [CITE: Bao et al. 2015] files (Drosophila and Anopheles TE references, plus simple-repeat and pseudogene references). RepeatMasker [CITE: Smit et al. 2013–2015] was then run against the assembly with this unified library in soft-masking mode. Fourth, repeat content statistics were recomputed for the six chromosome-scale scaffolds using `ProcessRepeats` on the pre-computed alignment archive, excluding low-complexity and simple repeat regions from the summary.

### 2.X Transposable element effects on genetic diversity

To test whether transposable elements (TEs) are associated with local patterns of genetic diversity, we combined the chromosome-scale repeat annotation with population-level SNP genotypes and modeled nucleotide diversity (π) as a function of TE presence, TE type, and TE age across the genome.

Per-insertion TE age was estimated as the Kimura-2-parameter genetic distance (corrected for CpG hypermutability) between each repeat copy and its family consensus sequence, extracted directly from the RepeatMasker alignment output; lower divergence indicates a more recently active, younger insertion, and higher divergence indicates an older, more degraded copy. Each TE insertion was additionally assigned a repeat class (the RepeatMasker class code, e.g., LINE, SINE, LTR, DNA, RC, or PLE) and collapsed into one of three transposable element orders — DNA transposons, retrotransposons (LINEs, SINEs, LTR elements, and Penelope-like elements), and rolling-circle (Helitron-like) elements — with all remaining non-TE or ambiguous repeat classes (simple repeats, low-complexity sequence, satellites, and unclassified elements) excluded from the TE analysis.

The genome was divided into non-overlapping 10 kb windows (with a 5 kb window size used as a sensitivity check) tiled across the six chromosome-scale scaffolds. Each window was annotated with the fraction of its sequence covered by annotated TEs, a binary indicator of TE presence, the set of TE orders and classes overlapping the window, and the mean Kimura divergence of any overlapping TEs. Nucleotide diversity was calculated for each window from the biallelic SNP genotypes using VCFtools [CITE: Danecek et al. 2011] `--window-pi`.

The relationship between window-level nucleotide diversity and TE characteristics was modeled using Bayesian regression, implemented with the `brms` R package [CITE: Bürkner 2017] and the Stan probabilistic programming language, assuming diversity follows a lognormal distribution. Four models were fit to address complementary questions: (1) whether π differs between windows with and without an annotated TE; (2) whether π differs among TE orders and scales with the fraction of a window occupied by TE sequence; (2b) whether π differs among the finer-grained TE classes; and (3) whether π is associated with TE age, using the mean Kimura divergence of TEs within a window (standardized to zero mean and unit variance). All models included chromosome as a covariate to account for broad-scale, chromosome-level variation in diversity that is independent of TE content. Models were run with four Markov chains and assessed for convergence using the potential scale reduction statistic (R-hat) and effective sample size.

### 2.X Results: Transposable elements and genetic diversity

All four models converged well (R-hat = 1.00 for every parameter; bulk and tail effective sample sizes exceeded 5,000 draws in all cases). Because diversity was modeled on the log scale, regression coefficients are reported below both as the raw estimate (natural-log scale) and as the corresponding multiplicative effect on π (back-transformed as *e*^estimate), together with the 95% credible interval (CrI).

**TE presence (Model 1).** Windows containing an annotated TE had lower nucleotide diversity than TE-free windows (estimate = −0.07, 95% CrI [−0.09, −0.05]), corresponding to π that was approximately 5–9% lower in TE-containing windows (fold-change 0.91–0.95; point estimate 0.93). The 95% credible interval excluded zero, indicating a credible negative association between TE presence and local diversity.

**TE order and TE fraction (Model 2).** Among TE-containing windows, diversity varied by TE order relative to DNA transposons (the reference level). Windows dominated by retrotransposons had modestly lower diversity (estimate = −0.04, 95% CrI [−0.07, −0.01]; ≈ 1–7% lower π), whereas windows containing rolling-circle elements had higher diversity (estimate = 0.08, 95% CrI [0.04, 0.13]; ≈ 4–14% higher π). The strongest effect in this model was the continuous fraction of a window occupied by TE sequence (estimate = −1.19, 95% CrI [−1.38, −0.99]), corresponding to an approximately 63–75% reduction in π across the full range of TE density (fold-change 0.25–0.37 at 100% TE coverage relative to 0% coverage). This indicates that the amount of TE sequence within a window, not merely its presence, is the dominant predictor of reduced local diversity.

**TE class (Model 2b).** At finer taxonomic resolution, LTR elements (estimate = −0.07, 95% CrI [−0.12, −0.03]; ≈ 3–11% lower π) and Penelope-like elements (PLE; estimate = −0.25, 95% CrI [−0.44, −0.05]; ≈ 5–36% lower π, with a wide interval reflecting the small number of PLE-containing windows) were associated with reduced diversity, while rolling-circle elements (estimate = 0.08, 95% CrI [0.04, 0.13]) and SINEs (estimate = 0.45, 95% CrI [0.08, 0.82]; ≈ 8–127% higher π, likewise imprecisely estimated owing to the rarity of SINE-containing windows) were associated with elevated diversity. LINE-containing windows did not differ credibly from the DNA transposon reference level (estimate = −0.03, 95% CrI [−0.06, 0.01]; interval spans zero). The TE-fraction effect was consistent with Model 2 (estimate = −1.17, 95% CrI [−1.36, −0.97]).

**TE age (Model 3).** Among TE-containing windows, mean TE age (standardized Kimura divergence) was weakly and only marginally associated with diversity (estimate = 0.01, 95% CrI [0.00, 0.02]), corresponding to approximately a 0–2% increase in π per standard deviation increase in Kimura divergence. Because the credible interval lower bound was at or near zero, this association should be interpreted as weak evidence for a small increase in diversity around older, more diverged TE insertions, rather than a strong or clearly established effect.

Across all four models, chromosome identity explained additional variation in diversity independent of TE content, with one scaffold (Chr05) showing consistently higher baseline diversity (≈ 32–41% higher than the reference chromosome) than the others.

---

## Suggested Citations

> Bao, W., Kojima, K.K. & Kohany, O. (2015). Repbase Update, a database of repetitive elements in eukaryotic genomes. *Mobile DNA*, 6, 11.

> Bürkner, P.-C. (2017). brms: An R Package for Bayesian Multilevel Models Using Stan. *Journal of Statistical Software*, 80(1), 1–28.

> Danecek, P. *et al.* (2011). The variant call format and VCFtools. *Bioinformatics*, 27(15), 2156–2158.

> Flynn, J.M. *et al.* (2020). RepeatModeler2 for automated genomic discovery of transposable element families. *Proceedings of the National Academy of Sciences*, 117(17), 9451–9457.

> Qian, J. *et al.* (2025). TEtrimmer: a tool to automate the manual curation of transposable elements. *Nature Communications*, 16, 8429.

> Smit, A.F.A., Hubley, R. & Green, P. (2013–2015). RepeatMasker Open-4.0. http://www.repeatmasker.org.

> Astashyn, A. *et al.* (2024). Rapid and sensitive detection of genome contamination at scale with FCS-GX. *Genome Biology*, 25, 60.

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
