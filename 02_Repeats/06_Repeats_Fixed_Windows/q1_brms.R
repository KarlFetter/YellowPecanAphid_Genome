# Q1: What is the effect of TE presence on nucleotide diversity (PI) in fixed windows?

library(brms)

# Set up inputs
work_dir <- "/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/fixed_windows_approach"
input_file <- file.path(work_dir, "genome_10kb_pi.tsv")
output_dir <- file.path(work_dir, "brms_models_Q1")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Create data frame
dat <- read.delim(input_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE,
                  check.names = FALSE, na.strings = c("NA", ""))

# Set data types
dat$PI <- as.numeric(dat$PI)
dat$TE_FRACTION <- as.numeric(dat$TE_FRACTION)
dat$MEAN_KIMURA_PERCENT <- as.numeric(dat$MEAN_KIMURA_PERCENT)
dat$TE_PRESENT <- factor(dat$TE_PRESENT, levels = c("FALSE", "TRUE"))
dat$CHROM <- factor(dat$CHROM)
dat$ORDER <- factor(dat$ORDER)

# Set weakly informative priors
priors <- c(
  prior(normal(0, 2), class = "b"),
  prior(student_t(3, 0, 2.5), class = "Intercept"),
  prior(exponential(1), class = "sigma")
)

# Q1: Do windows containing TEs differ from windows without TEs?
q1 <- brm(
  PI ~ TE_PRESENT + CHROM,
  data = dat,
  family = lognormal(),
  prior = priors,
  chains = 4, cores = 4, iter = 10000, warmup = 2000,
  seed = 20260902
)

save(q1, file="q1.bmrs")

summary(q1)