# Yellow Pecan Aphid (*Monelliopsis pecanis*) Genome

[![GitHub](https://img.shields.io/badge/GitHub-KarlFetter%2FYellowPecanAphid__Genome-blue)](https://github.com/KarlFetter/YellowPecanAphid_Genome)

This repository contains the bioinformatic pipelines and analysis scripts for the reference genome assembly of the yellow pecan aphid, *Monelliopsis pecanis*  (Bissell, 1983). These analyses support a manuscript describing the first chromosome-scale genome assembly for this species, sequenced with Pacific Biosciences HiFi long reads and Oxford Nanopore Technologies ultra-long reads. Comparative genomic analyses are described.

---

## Species

| Attribute | Value |
|---|---|
| Common name | Yellow pecan aphid |
| Scientific name | *Monelliopsis pecanis* (Fitch, 1855) |
| Order | Hemiptera |
| Family | Aphididae |
| Subfamily | Drepanosiphinae |
| Primary host | Pecan (*Carya illinoinensis*) |
| NCBI Taxon ID | 2982816 |

---

## Repository Structure

```
YellowPecanAphid_Genome/
├── README.md              
├── LICENSE
├── .gitignore
├── Assembly/              ← Genome assembly pipeline
│   ├── README.md          ← Assembly documentation
│   ├── 01_raw_reads/      ← BAM-to-FASTQ conversion, read QC
│   ├── 03_genome_size/    ← k-mer counting (Jellyfish/GenomeScope2)
│   ├── 04_assembly/       ← hifiasm and Verkko assemblies
│   ├── 05_purge_haplotigs/← Haplotig purging (purge_dups)
│   ├── 06_scaffolding/    ← Scaffolding and gap-filling (SAMBA)
│   ├── 07_contam_filter/  ← BlobToolKit and NCBI FCS-GX screens
│   ├── 08_final_draft_assembly/ ← BUSCO, QUAST, coverage QC
│   ├── 09_coverage/       ← Genome-wide windowed coverage
│   └── 10_soft_masked_draft/    ← Chromosome-level filtering, HISAT2 index
└── Repeats/               ← Repeat annotation pipeline
    ├── README.md          ← Repeat pipeline documentation
    ├── 01_RepeatModeler/  ← De novo repeat discovery (RepeatModeler2)
    ├── 02_TEtrimmer/      ← TE library curation (TEtrimmer)
    └── 03_RepeatMasker/   ← Soft-masking (RepeatMasker)
```

---

## Genome Assembly

See [Assembly/README.md](Assembly/README.md) for a step-by-step description of the full assembly pipeline, including:

- PacBio HiFi and Oxford Nanopore read processing
- Genome size estimation via k-mer analysis
- De novo assembly with hifiasm (HiFi-only and HiFi+ONT ultra-long) and Verkko
- Haplotig purging with purge_dups
- Scaffolding and gap-filling with SAMBA (MaSuRCA)
- Contamination screening with BlobToolKit and NCBI FCS-GX
- Assembly quality assessment with BUSCO and QUAST

---

## Repeat Annotation

See [Repeats/README.md](Repeats/README.md) for a description of the full repeat identification and soft-masking pipeline, including:

- De novo repeat family discovery with RepeatModeler2 (RECON, RepeatScout, LTRStruct)
- Automated curation and classification of the TE consensus library with TEtrimmer
- Soft-masking with a unified library of de novo and curated Insecta repeats (RepeatMasker)

---

## Data Availability

Raw sequencing reads and the final genome assembly are deposited in NCBI under:

- **BioProject**: [PLACEHOLDER — accession]
- **GenBank assembly**: [PLACEHOLDER — accession]
- **SRA HiFi reads**: [PLACEHOLDER — accession]
- **SRA ONT reads**: [PLACEHOLDER — accession]

---

## Citation

> [PLACEHOLDER — complete citation upon acceptance]
>
> Fetter, K.C. *et al.* (in prep). Chromosome-scale genome assembly of the yellow pecan aphid, *Monelliopsis pecanis*.

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
