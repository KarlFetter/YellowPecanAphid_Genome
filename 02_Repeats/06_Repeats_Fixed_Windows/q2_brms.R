# Q2: Among TE-containing windows, does PI differ among repeat type?

library(brms)
library(tidyr)
library(dplyr)

# Set up inputs
work_dir <- "/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/fixed_windows_approach"
input_file <- file.path(work_dir, "genome_10kb_pi.tsv")
output_dir <- file.path(work_dir, "brms_models_Q1")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

dat <- read.delim(input_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE,
                  check.names = FALSE, na.strings = c("NA", ""))

# Set data types
dat$PI <- as.numeric(dat$PI)
dat$TE_FRACTION <- as.numeric(dat$TE_FRACTION)
dat$MEAN_KIMURA_PERCENT <- as.numeric(dat$MEAN_KIMURA_PERCENT)
dat$TE_PRESENT <- factor(dat$TE_PRESENT, levels = c("FALSE", "TRUE"))
dat$CHROM <- factor(dat$CHROM)
dat$ORDER <- factor(dat$ORDER)

# VCFtools reports windows with variant observations, so PI is positive in the
# current table. Model its right-skewed distribution on the log scale.
priors <- c(
  prior(normal(0, 2), class = "b"),
  prior(student_t(3, 0, 2.5), class = "Intercept"),
  prior(exponential(1), class = "sigma")
)

# Make the Q2 dataset
q2_data <- subset(dat, TE_PRESENT == "TRUE" & !is.na(ORDER) & ORDER != "NONE")
q2_data$ORDER <- droplevels(q2_data$ORDER)

# Modify q2_data from wide to long. Each level of ORDER will be a separate row, with the corresponding PI value.  
q2_data_long <- dat %>%
  filter(TE_PRESENT == "TRUE", 
         !is.na(ORDER), 
         ORDER != "NONE") %>%
  separate_rows(ORDER, sep = ";") %>%
  mutate(ORDER = as.character(ORDER)) %>%
  filter(ORDER != "") %>%
  mutate(ORDER = factor(ORDER))

# Q2: Among TE-containing windows, does PI differ among high-level orders?
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

saveRDS(q2, file.path(output_dir, "fixed_windows_brms_models.rds"))
