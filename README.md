# Yellow Pecan Aphid (*Monelliopsis pecanis*) Genome

[![GitHub](https://img.shields.io/badge/GitHub-KarlFetter%2FYellowPecanAphid__Genome-blue)](https://github.com/KarlFetter/YellowPecanAphid_Genome)

This repository contains the bioinformatic pipelines and analysis scripts for the reference genome assembly of the yellow pecan aphid, *Monelliopsis pecanis*  (Bissell, 1983). These analyses support a manuscript describing the first chromosome-scale genome assembly for this species, sequenced with Pacific Biosciences HiFi long reads and Oxford Nanopore Technologies ultra-long reads. Comparative genomic analyses are described.

---

## Species

| Attribute | Value |
|---|---|
| Common name | Yellow pecan aphid |
| Scientific name | *Monelliopsis pecanis* (Bissell, 1983) |
| Order | Hemiptera |
| Family | Aphididae |
| Subfamily | Drepanosiphinae |
| Primary host | Pecan (*Carya illinoinensis*) |
| NCBI Taxon ID | 2982816 |

---

## Repository Structure

```
YellowPecanAphid_Genome/
├── .gitignore
├── LICENSE
├── METHODS.md             ← Detailed manuscript methods
├── README.md
├── references.bib         ← Manuscript references
├── 01_Assembly/           ← Genome assembly pipeline
│   ├── README.md          ← Assembly documentation
│   ├── 01_raw_reads/      ← BAM-to-FASTQ conversion, read QC
│   ├── 03_genome_size/    ← k-mer counting (Jellyfish/GenomeScope2)
│   ├── 04_assembly/       ← hifiasm and Verkko assemblies
│   ├── 05_purge_haplotigs/← Haplotig purging (purge_dups)
│   ├── 06_scaffolding/    ← Scaffolding and gap-filling (SAMBA)
│   ├── 07_contam_filter/  ← NCBI FCS-GX contamination screening
│   ├── 08_final_draft_assembly/ ← BUSCO, QUAST, coverage QC
│   ├── 09_coverage/       ← Genome-wide windowed coverage
│   └── 10_soft_masked_draft/    ← Chromosome-level filtering, HISAT2 index
├── 02_Repeats/            ← Repeat annotation pipeline
│   ├── README.md          ← Repeat pipeline documentation
│   ├── 01_RepeatModeler/  ← De novo repeat discovery (RepeatModeler2)
│   ├── 02_TEtrimmer/      ← TE library curation (TEtrimmer)
│   ├── 03_RepeatMasker/   ← Soft-masking (RepeatMasker)
│   ├── 04_RM_Report_Top6Scaffolds/ ← Chromosome-scale repeat report
│   └── 05_Repeats_Fixed_Windows/   ← Fixed-window TE and π data preparation
├── 03_Annotation/         ← Structural and functional genome annotation
│   ├── 01_predict_genes_funannotate.sh
│   ├── 02_functional_annotation_funannotate.sh
│   ├── 03_interproscan.sh
│   └── 04_busco_proteins.sh
├── 04_Population_Genomics/ ← SNP calling, filtering, and nucleotide diversity
│   ├── 01_call_snps.sh
│   ├── 02_filter_snps.sh
│   ├── 03_subset_chromosomes.sh
│   └── 04_calculate_pi.sh
├── 05_Regression_Models/ ← Bayesian models of TE effects on nucleotide diversity
│   ├── README.md          ← Model formulas and shared settings
│   ├── 03_q1_brms.R       ← TE presence model
│   ├── 04_q2_brms.R       ← TE order and class models
│   └── 05_q3_brms.R       ← TE age model
├── circos/
│   ├── 01_prep_inputs.sh  ← Circos karyotype, SNP-density, and π inputs
│   └── extract_kimura_align.py ← RepeatMasker Kimura parser used for modeling
└── figure_making/         ← Circos, coverage, repeat, and TE-diversity figures
```

---

## Genome Assembly

See [01_Assembly/README.md](01_Assembly/README.md) for a step-by-step description of the full assembly pipeline, including:

- PacBio HiFi and Oxford Nanopore read processing
- Genome size estimation via k-mer analysis
- De novo assembly with hifiasm (HiFi-only and HiFi+ONT ultra-long) and Verkko
- Haplotig purging with purge_dups
- Scaffolding and gap-filling with SAMBA (MaSuRCA)
- Contamination screening with NCBI FCS-GX
- Assembly quality assessment with BUSCO and QUAST

---

## Repeat Annotation

See [02_Repeats/README.md](02_Repeats/README.md) for a description of the full repeat identification and soft-masking pipeline, including:

- De novo repeat family discovery with RepeatModeler2 (RECON, RepeatScout, LTRStruct)
- Automated curation and classification of the TE consensus library with TEtrimmer
- Soft-masking with a unified library of de novo and curated Insecta repeats (RepeatMasker)
- Per-insertion Kimura divergence extraction with [`circos/extract_kimura_align.py`](circos/extract_kimura_align.py)
- Fixed-window TE and nucleotide-diversity data preparation (`02_Repeats/05_Repeats_Fixed_Windows/`)

---

## Regression Models

See [05_Regression_Models/README.md](05_Regression_Models/README.md) for the four primary Bayesian models testing TE presence, TE order, TE class, and TE age as predictors of nucleotide diversity.

---

## Data Availability

Raw sequencing reads and the final genome assembly are deposited in NCBI under:

- **BioProject**: PRJNA1519993
- **GenBank assembly**: [PROCESSING]
- **SRA HiFi reads**: SRR40386561
- **SRA ONT reads**: SRR40386560

---

## Citation

> Fetter, K.C., Chen, H.C., Cottrell, T. (in prep). Transposable elements suppress genetic diversity in the Yellow Pecan Aphid (*Monelliopsis pecanis*) genome. Submitted to G3 Genes|Genomes|Genetics

---

## Contact

**Karl C. Fetter**  
USDA Agricultural Research Service  
Southeastern Fruit and Tree Nut Research Laboratory  
Byron, GA  
[karl.fetter@usda.gov](mailto:karl.fetter@usda.gov)  
GitHub: [@KarlFetter](https://github.com/KarlFetter)

---

## License

This work was produced by a United States Government employee as part of their official duties. See [LICENSE](LICENSE) for details.
