# Q3 Code.
library(brms)

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

# Generate weakly informative priors for the model
priors <- c(
  prior(normal(0, 2), class = "b"),
  prior(student_t(3, 0, 2.5), class = "Intercept"),
  prior(exponential(1), class = "sigma")
)

# Q3: Among TE-containing windows with an age value, does PI vary with age?
q3_data <- subset(dat, TE_PRESENT == "TRUE" & is.finite(MEAN_KIMURA_PERCENT))
q3_data$KIMURA_SCALED <- as.numeric(scale(q3_data$MEAN_KIMURA_PERCENT))


# Fit the model 
q3 <- brm(
  PI ~ KIMURA_SCALED + TE_FRACTION + CHROM,
  data = q3_data,
  family = lognormal(),
  prior = priors,
  chains = 4, cores = 4, iter = 4000, warmup = 2000,
  seed = 20260902,
  file = file.path(output_dir, "q3_kimura_age")
)

saveRDS(q3, file.path(output_dir, "q3_kimura_age.rds"))
