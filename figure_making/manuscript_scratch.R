# Manuscript statistic notes

# Set ups for script
setwd("C:/Users/Karl.Fetter/aphid")
library(tidyverse)
library(brms)

## K2P And Pi data
# Read in the data
dat <- read.table("repeat_ages_kimura.tsv",T,'\t')

# Fix some stings & Reorder levels
plot_dat <- dat %>% 
  mutate(
    repeat_order = str_replace_all(repeat_order, c(
      "DNA_transposon" = "DNA Transposon",
      "Rolling_Circle" = "Rolling Circles",
      "Unknown"        = "Unclassified"
    )),
    repeat_order = factor(repeat_order, levels = c(
      "DNA Transposon", 
      "Retrotransposon", 
      "Rolling Circles", 
      "Unclassified"
    )),
    repeat_class = str_replace_all(repeat_class, c(
      "Satellite"   = "Satellites",
      "Unknown"     = "Unclassified",
      "Unspecified" = "Unclassified"
    )),
    repeat_class = factor(repeat_class, levels = c(
      "DNA", "LINE", "LTR", "PLE", "SINE", "RC", "Satellites", "Unclassified"
    ))
  )

# Mean of K2p ~ Order
order_k2p_means <- plot_dat %>% 
  group_by(repeat_order) %>% 
  summarize(means = mean(kimura_percent, na.rm = TRUE))
order_k2p_means

# sd of K2p ~ Order
order_k2p_sd <- plot_dat %>% 
  group_by(repeat_order) %>% 
  summarize(sd = sd(kimura_percent, na.rm = TRUE))
order_k2p_sd

# Mean of K2p ~ Class
class_k2p_means <- plot_dat %>% 
  group_by(repeat_class) %>% 
  summarize(means = mean(kimura_percent, na.rm = TRUE))
class_k2p_means

# Mean of K2p ~ Class
class_k2p_sd <- plot_dat %>% 
  group_by(repeat_class) %>% 
  summarize(sd = mean(kimura_percent, na.rm = TRUE))
class_k2p_sd


# Do classified repeats have a different distribution than non-classified repeats?


dat_mod0 <- plot_dat %>%
  select(repeat_size, repeat_class) %>%
  mutate(
    classification = if_else(repeat_class == "Unclassified", "Unclassified", "Classified"),
    classification = factor(classification, levels = c("Classified", "Unclassified"))
  )

# Quick anova.

dat_mod0 <- dat_mod0 %>% mutate(log_size = log(repeat_size))

fit_aov <- aov(log_size ~ classification, data = dat_mod0)
summary(fit_aov)

# check assumptions
par(mfrow = c(2,2)); plot(fit_aov)

# non-parametric fallback (recommended given TE size distributions are rarely normal even on log scale)
kruskal.test(repeat_size ~ classification, data = dat_mod0)



# Nucleotide Diversity models
pi_dat <- read.table("genome_10kb_pi.tsv",T,'\t')

# summary stats
summary(pi_dat$PI)


# Coverage information from 100kb windows
library(tidyverse)
setwd("/90daydata/tgl_seqdata/aphids/assembly/ypa/09_coverage/primary")

# Read in summaries & view them
hifi_summary = read.table("ypa_hifi_chrom_coverage.txt",T,',')
ont_summary = read.table("ypa_ont_chrom_coverage.txt",T,',')

# Read in the data for each type for the 100 kb windows.
hifi = read.table("ypa_primary_hifi_100kb_coverage.txt",F,'\t')
ont = read.table("ypa_primary_ont_100kb_coverage.txt",F,'\t')

names(hifi) <- c("scaffold", "start", "end", "coverage")
names(ont) <- c("scaffold", "start", "end", "coverage") 

# Retain the six chromosome-scale scaffolds.
scaffold_map <- c(
  "ptg000001l_1" = "chr1",
  "ptg000004l_1" = "chr2",
  "ptg000003l_1" = "chr3",
  "ptg000002l_1" = "chr4",
  "ptg000005l_1" = "chr5",
  "ptg000006l_1" = "chr6"
)

ont <- ont %>%
  filter(scaffold %in% names(scaffold_map)) %>%
  mutate(scaffold = recode(scaffold, !!!scaffold_map))

hifi <- hifi %>%
  filter(scaffold %in% names(scaffold_map)) %>%
  mutate(scaffold = recode(scaffold, !!!scaffold_map))

## Look at PI dynamics in the 10kb windows
pi = read.table("/90daydata/tgl_seqdata/aphids/circos/ypa/primary/ypa_pi_10kb.windowed.pi",T,'\t')

# Make a summary table of median, mean, min, and max PI for each chromosome
pi_summary <- pi %>%
  group_by(CHROM) %>%
  summarize(
    median_PI = median(PI, na.rm = TRUE),
    mean_PI = mean(PI, na.rm = TRUE),
    min_PI = min(PI, na.rm = TRUE),
    max_PI = max(PI, na.rm = TRUE)
  )
pi_summary


# How many aphid species on NCBI?
setwd("C:/Users/Karl.Fetter/aphid")
aphid = read.table("aphididae_genomes_on_NCBI.tsv",T,'\t')

# How many species represented?
length(unique(aphid$Organism.Name))

# What level of assembly are they?
table(aphid$Assembly.Level)

