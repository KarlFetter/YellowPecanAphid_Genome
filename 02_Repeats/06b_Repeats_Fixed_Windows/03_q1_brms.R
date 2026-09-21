# Q1: Does TE presence in a fixed window affect nucleotide diversity (PI)?
library(brms)

work_dir <- "/90daydata/tgl_seqdata/aphids/repeats/ypa/05b_Repeats_GeneticDiv/fixed_windows"
input_file <- file.path(work_dir, "genome_10kb_pi.tsv")
output_dir <- file.path(work_dir, "brms_models")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

dat <- read.delim(input_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE,
                  check.names = FALSE, na.strings = c("NA", ""))

dat$PI <- as.numeric(dat$PI)
dat$TE_FRACTION <- as.numeric(dat$TE_FRACTION)
dat$MEAN_KIMURA_PERCENT <- as.numeric(dat$MEAN_KIMURA_PERCENT)
dat$TE_PRESENT <- factor(dat$TE_PRESENT, levels = c("FALSE", "TRUE"))
dat$CHROM <- factor(dat$CHROM)
dat$ORDER <- factor(dat$ORDER)

priors <- c(
  prior(normal(0, 2), class = "b"),
  prior(student_t(3, 0, 2.5), class = "Intercept"),
  prior(exponential(1), class = "sigma")
)

q1 <- brm(
  PI ~ TE_PRESENT + CHROM,
  data = dat,
  family = lognormal(),
  prior = priors,
  chains = 4, cores = 4, iter = 4000, warmup = 2000,
  seed = 20260902,
  file = file.path(output_dir, "q1_te_presence")
)

summary(q1)
