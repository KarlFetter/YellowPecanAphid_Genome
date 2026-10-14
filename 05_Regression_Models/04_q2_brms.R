# Q2: Among TE-containing windows, does PI differ by repeat order or repeat class?
library(brms)
library(tidyr)
library(dplyr)

# Set up inputs and output directories
work_dir <- "/90daydata/tgl_seqdata/aphids/repeats/ypa/05b_Repeats_GeneticDiv/fixed_windows"
input_file <- file.path(work_dir, "genome_10kb_pi.tsv")
output_dir <- file.path(work_dir, "brms_models")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Read in data and prep variables
dat <- read.delim(input_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE,
                  check.names = FALSE, na.strings = c("NA", ""))

dat$PI <- as.numeric(dat$PI)
dat$TE_FRACTION <- as.numeric(dat$TE_FRACTION)
dat$MEAN_KIMURA_PERCENT <- as.numeric(dat$MEAN_KIMURA_PERCENT)
dat$TE_PRESENT <- factor(dat$TE_PRESENT, levels = c("FALSE", "TRUE"))
dat$CHROM <- factor(dat$CHROM)

# Set priors
priors <- c(
  prior(normal(0, 2), class = "b"),
  prior(student_t(3, 0, 2.5), class = "Intercept"),
  prior(exponential(1), class = "sigma")
)

# A window can overlap multiple distinct ORDER/CLASS values; long-format one row per value.
q2_data_long <- dat %>%
  filter(TE_PRESENT == "TRUE", !is.na(ORDER), ORDER != "NONE") %>%
  separate_rows(ORDER, sep = ";") %>%
  mutate(ORDER = as.character(ORDER)) %>%
  filter(ORDER != "") %>%
  mutate(ORDER = factor(ORDER))

# fit brms model for TE order
q2 <- brm(
  PI ~ CHROM + ORDER + TE_FRACTION,
  data = q2_data_long,
  family = lognormal(),
  prior = priors,
  chains = 4, cores = 4, iter = 4000, warmup = 2000,
  seed = 20260902,
  file = file.path(output_dir, "q2_te_order")
)
summary(q2)

# convert from wide to long
q2b_data_long <- dat %>%
  filter(TE_PRESENT == "TRUE", !is.na(CLASS), CLASS != "NONE") %>%
  separate_rows(CLASS, sep = ";") %>%
  mutate(CLASS = as.character(CLASS)) %>%
  filter(CLASS != "") %>%
  mutate(CLASS = factor(CLASS))

# fit brms model
q2b <- brm(
  PI ~ CHROM + CLASS + TE_FRACTION,
  data = q2b_data_long,
  family = lognormal(),
  prior = priors,
  chains = 4, cores = 4, iter = 4000, warmup = 2000,
  seed = 20260902,
  file = file.path(output_dir, "q2_te_class")
)
summary(q2b)

