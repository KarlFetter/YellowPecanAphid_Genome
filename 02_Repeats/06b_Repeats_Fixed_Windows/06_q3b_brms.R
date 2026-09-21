# Q3b: Among TE-containing windows, does PI vary with mean repeat (Kimura) age and how do the slopes of class differ?
library(brms)
library(dplyr)
library(tidyr)

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

priors <- c(
  prior(normal(0, 2), class = "b"),
  prior(student_t(3, 0, 2.5), class = "Intercept"),
  prior(exponential(1), class = "sigma")
)

q3_data <- subset(dat, TE_PRESENT == "TRUE" & is.finite(MEAN_KIMURA_PERCENT))
q3_data$KIMURA_SCALED <- as.numeric(scale(q3_data$MEAN_KIMURA_PERCENT))

# CLASS holds semicolon-joined combinations (e.g. "DNA;LINE") for windows overlapping
# multiple TE classes; expand to one row per class so CLASS groups on the 6 real classes
q3_data_long <- q3_data %>%
  separate_rows(CLASS, sep = ";") %>%
  filter(CLASS != "", CLASS != "NONE") %>%
  mutate(CLASS = factor(CLASS))

q3b <- brm(
  PI ~ KIMURA_SCALED + CHROM + (KIMURA_SCALED | CLASS),
  data = q3_data_long,
  family = lognormal(),
  prior = priors,
  chains = 4, cores = 4, iter = 20000, warmup = 4000,
  seed = 20260902,
  file = file.path(output_dir, "q3b_kimura_age")
)
summary(q3b)

cat("Kimura scaling center:", attr(scale(q3_data$MEAN_KIMURA_PERCENT), "scaled:center"), "\n")
cat("Kimura scaling scale:", attr(scale(q3_data$MEAN_KIMURA_PERCENT), "scaled:scale"), "\n")