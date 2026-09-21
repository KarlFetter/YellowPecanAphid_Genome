# Fixed Windows Approach: brms models for Q1-Q3.
# The response is VCFtools PI from one diploid individual, not population pi.

library(brms)

work_dir <- "/90daydata/tgl_seqdata/aphids/repeats/ypa/05_Repeats_GeneticDiv/fixed_windows_approach"
input_file <- file.path(work_dir, "genome_10kb_pi.tsv")
output_dir <- file.path(work_dir, "brms_models")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

dat <- read.delim(input_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE,
                  check.names = FALSE, na.strings = c("NA", ""))

required <- c("CHROM", "PI", "TE_PRESENT", "TE_FRACTION", "ORDER",
              "FAMILY", "MEAN_KIMURA_PERCENT")
missing <- setdiff(required, names(dat))
if (length(missing) > 0) {
  stop("Missing columns: ", paste(missing, collapse = ", "))
}

dat$PI <- as.numeric(dat$PI)
dat$TE_FRACTION <- as.numeric(dat$TE_FRACTION)
dat$MEAN_KIMURA_PERCENT <- as.numeric(dat$MEAN_KIMURA_PERCENT)
dat$TE_PRESENT <- factor(dat$TE_PRESENT, levels = c("FALSE", "TRUE"))
dat$CHROM <- factor(dat$CHROM)
dat$ORDER <- factor(dat$ORDER)

if (any(!is.finite(dat$PI) | dat$PI < 0)) {
  stop("PI contains negative or non-finite values")
}
if (nrow(dat) < 20) {
  stop("Too few fixed windows for modeling: ", nrow(dat))
}

# VCFtools reports windows with variant observations, so PI is positive in the
# current table. Model its right-skewed distribution on the log scale.
pi_family <- lognormal()
common_priors <- c(
  prior(normal(0, 2), class = "b"),
  prior(student_t(3, 0, 2.5), class = "Intercept"),
  prior(exponential(1), class = "sd"),
  prior(exponential(1), class = "shape")
)

# Q1: Do windows containing TEs differ from windows without TEs?
q1_data <- dat[complete.cases(dat[, c("PI", "TE_PRESENT", "CHROM")]), ]
q1 <- brm(
  PI ~ TE_PRESENT + CHROM,
  data = q1_data,
  family = pi_family,
  prior = common_priors,
  chains = 4, cores = 4, iter = 4000, warmup = 2000,
  seed = 20260902,
  file = file.path(output_dir, "q1_te_presence")
)

# Q2: Among TE-containing windows, does PI differ among high-level orders?
q2_data <- subset(dat, TE_PRESENT == "TRUE" & !is.na(ORDER) & ORDER != "NONE")
q2_data$ORDER <- droplevels(q2_data$ORDER)
q2 <- brm(
  PI ~ ORDER + TE_FRACTION + CHROM,
  data = q2_data,
  family = pi_family,
  prior = common_priors,
  chains = 4, cores = 4, iter = 4000, warmup = 2000,
  seed = 20260902,
  file = file.path(output_dir, "q2_te_order")
)

# Q3: Among TE-containing windows with an age value, does PI vary with age?
q3_data <- subset(dat, TE_PRESENT == "TRUE" & is.finite(MEAN_KIMURA_PERCENT))
q3_data$KIMURA_SCALED <- as.numeric(scale(q3_data$MEAN_KIMURA_PERCENT))
q3 <- brm(
  PI ~ KIMURA_SCALED + TE_FRACTION + CHROM,
  data = q3_data,
  family = pi_family,
  prior = common_priors,
  chains = 4, cores = 4, iter = 4000, warmup = 2000,
  seed = 20260902,
  file = file.path(output_dir, "q3_kimura_age")
)

saveRDS(list(q1 = q1, q2 = q2, q3 = q3),
        file.path(output_dir, "fixed_windows_brms_models.rds"))
writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))