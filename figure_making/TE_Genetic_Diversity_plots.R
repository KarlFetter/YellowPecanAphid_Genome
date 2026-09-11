# Make publication ready figures
library(brms)
library(tidverse)
library(ggplot2)
library(patchwork)

#Q1
load("C:/Users/Karl.Fetter/aphid/brms_models.rds/brms_models_Q1/q1.brms")
ce_plot_q1 <- conditional_effects(q1)

# Plot the chromosome plot
# 1. Extract the data frame from the conditional effects list
chrom_data <- ce_plot_q1[["CHROM"]]

# 2. Rearrange the factor levels so the mapped outputs line up from Chr01 to Chr06
desired_order <- c(
  "ptg000001l_1", # Chr01
  "ptg000004l_1", # Chr02
  "ptg000003l_1", # Chr03
  "ptg000002l_1", # Chr04
  "ptg000005l_1", # Chr05
  "ptg000006l_1"  # Chr06
)

# 3. Apply the sorted order to the factor
chrom_data$CHROM <- factor(chrom_data$CHROM, levels = desired_order)

# 4. Generate the plot
p_q1_chrom <- ggplot(chrom_data, aes(x = CHROM, y = estimate__, ymin = lower__, ymax = upper__)) + 
  geom_errorbar(width = 0.2, linewidth = 0.8) + 
  geom_point(size = 4) + 
  scale_x_discrete(labels = c(
    "ptg000001l_1" = "Chr01",
    "ptg000004l_1" = "Chr02",
    "ptg000003l_1" = "Chr03",
    "ptg000002l_1" = "Chr04",
    "ptg000005l_1" = "Chr05",
    "ptg000006l_1" = "Chr06"
  )) +
  labs( 
    x = "", 
    y = expression(paste(pi)) 
  ) + 
  theme_bw(base_size = 14) + 
  theme( 
    panel.grid.minor = element_blank(), 
    panel.grid.major = element_line(color = "#f0f0f0"), 
    panel.border = element_blank(), 
    axis.line = element_line(color = "black", linewidth = 0.6), 
    axis.text = element_text(color = "black"), 
    axis.title.y = element_text(size = 14),
    axis.text.x = element_text(size = 10, angle = -45, hjust = -0.1)
  )
p_q1_chrom


# View the main plot of the model, TE Presence
p_q1 <- ggplot(ce_plot_q1[["TE_PRESENT"]], aes(x = TE_PRESENT, y = estimate__, ymin = lower__, ymax = upper__)) +
  geom_errorbar(width = 0.2, linewidth = 0.8) +
  geom_point(size = 4) +
  labs(
    x ="",
    y = expression(paste(pi))
  ) +
  theme_bw(base_size = 14) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.border = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.6),
    axis.text = element_text(color = "black"),
    axis.title.y = element_text(size = 14),
    axis.text.x = element_text(angle = -45, hjust=0)
  ) +
  scale_x_discrete(labels = c(
    "FALSE"   = "TE Absent\nin Window",
    "TRUE"  = "TE Present\nin Window"
  ))

p_q1

#Q2
q2 <- readRDS("C:/Users/Karl.Fetter/aphid/brms_models/brms_models_Q1/q2_te_order.rds")

# Make CE plots
ce_plot_q2 <- conditional_effects(q2)

# plot the effect of order
p_q2_order <- ggplot(ce_plot_q2[["ORDER"]], aes(x = ORDER, y = estimate__, ymin = lower__, ymax = upper__)) +
  geom_errorbar(width = 0.2, linewidth = 0.8) +
  geom_point(size = 4) +
  labs(
    x ="",
    y = expression(paste(pi))
  ) +
  theme_bw(base_size = 14) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.border = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.6),
    axis.text = element_text(color = "black"),
    axis.title.y = element_text(size = 14),
    axis.text.x = element_text(angle = -45, hjust=0)
  ) +
  scale_x_discrete(labels = c(
    "DNA_transposon" = "DNA\nTransposon",
    "Retroelement"   = "Retrotransposon",
    "RollingCircle"  = "Rolling Circle"
  ))

# Plot the effect of TE Class
q2b <- readRDS("C:/Users/Karl.Fetter/aphid/brms_models.rds/brms_models_Q1/q2_te_class.rds")
ce_plot_q2b <- conditional_effects(q2b)

p_q2b_class <- ggplot(ce_plot_q2b[["CLASS"]], aes(x = CLASS, y = estimate__, ymin = lower__, ymax = upper__)) +
  geom_errorbar(width = 0.2, linewidth = 0.8) +
  geom_point(size = 3) +
  labs(
    x ="",
    y = expression(paste(pi))
  ) +
  theme_bw(base_size = 14) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.border = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.6),
    axis.text = element_text(color = "black"),
    axis.title.y = element_text(size = 14),
    axis.text.x = element_text(angle = -45, hjust=0)
  )
p_q2b_class

# Plot TE Fraction effect
p_TE_fraction <- ggplot(ce_plot_q2[["TE_FRACTION"]], aes(x = TE_FRACTION, y = estimate__)) + 
  geom_ribbon(aes(ymin = lower__, ymax = upper__), fill = "grey80", alpha = 0.5) + 
  geom_line(linewidth = 1.2) + 
  labs(x = "Fraction of Window\nContaining TE", y = expression(paste(pi))) + 
  theme_bw(base_size = 14) + 
  theme( 
    panel.grid.minor = element_blank(), 
    panel.grid.major = element_line(color = "#f0f0f0"), 
    panel.border = element_blank(), 
    axis.line = element_line(color = "black", linewidth = 0.6), 
    axis.text = element_text(color = "black"), 
    axis.title.y = element_text(size = 14),
    # Aggressively pulls text up (-35) and pads the bottom (+35) so it doesn't clip
    axis.title.x = element_text(margin = margin(t = -25, b = 35)) 
  )

#Q3 Plots
q3 <- readRDS("C:/Users/Karl.Fetter/aphid/brms_models.rds/brms_models_Q1/q3_kimura_age.rds")

# Take a look at the data
dat <- read.table("genome_10kb_pi.tsv", T, '\t')

# Set data types
dat$PI <- as.numeric(dat$PI)
dat$TE_FRACTION <- as.numeric(dat$TE_FRACTION)
dat$MEAN_KIMURA_PERCENT <- as.numeric(dat$MEAN_KIMURA_PERCENT)
dat$TE_PRESENT <- factor(dat$TE_PRESENT, levels = c("FALSE", "TRUE"))
dat$CHROM <- factor(dat$CHROM)
dat$ORDER <- factor(dat$ORDER)

# Q3: Among TE-containing windows with an age value, does PI vary with age?
q3_data <- subset(dat, TE_PRESENT == "TRUE" & is.finite(MEAN_KIMURA_PERCENT))
q3_data$KIMURA_SCALED <- as.numeric(scale(q3_data$MEAN_KIMURA_PERCENT))

# View the data.
ggplot(q3_data, aes(x=KIMURA_SCALED, y=PI)) + 
  geom_point()

plot(x=q3_data$KIMURA_SCALED, y=q3_data$PI)
abline(lm(PI ~ KIMURA_SCALED, data = q3_data))


# Q3b plots
q3b <- readRDS("C:/Users/Karl.Fetter/aphid/brms_models.rds/brms_models_Q1/q3b_kimura_age.rds")

# Isolate the conditional effect plots
ce_plot_q3b <- conditional_effects(q3b)

# Plot K2 against Pi
p_kimura_age <- ggplot(ce_plot_q3b[["KIMURA_SCALED"]], aes(x = KIMURA_SCALED, y = estimate__)) + 
  geom_ribbon(aes(ymin = lower__, ymax = upper__), fill = "grey80", alpha = 0.5) + 
  geom_line(linewidth = 1.2) + 
  labs(x = "Kimura substitution\n(scaled)", y = expression(paste(pi))) + 
  theme_bw(base_size = 14) + 
  theme( 
    panel.grid.minor = element_blank(), 
    panel.grid.major = element_line(color = "#f0f0f0"), 
    panel.border = element_blank(), 
    axis.line = element_line(color = "black", linewidth = 0.6), 
    axis.text = element_text(color = "black"), 
    axis.title.y = element_text(size = 14),
    # Aggressively pulls text up (-35) and pads the bottom (+35) so it doesn't clip
    axis.title.x = element_text(margin = margin(t = -35, b = 10)) 
  )


# Multi-panel plot
# 1. Put all plots into a temporary list
all_plots <- list(p_q1_chrom, p_q1, p_TE_fraction, p_q2_order, p_q2b_class, p_kimura_age)

# 2. Automatically find 'geom_point' in any panel and change size to 2.5
all_plots <- lapply(all_plots, function(p) {
  for (i in seq_along(p$layers)) {
    if (inherits(p$layers[[i]]$geom, "GeomPoint")) {
      p$layers[[i]]$aes_params$size <- 2.5
    }
  }
  return(p)
})

# 3. Build the multi-panel plot
multipanel_plot <- (all_plots[[1]] + all_plots[[2]] + all_plots[[3]]) / 
  (all_plots[[4]] + all_plots[[5]] + all_plots[[6]])

# 4. Apply the lowercase tag sequence starting at 'c'
multipanel_plot <- multipanel_plot + 
  plot_annotation(
    tag_levels = list(c("c", "d", "e", "f", "g", "h"))
  ) & 
  theme(
    plot.tag = element_text(face = "plain", size = 28)
  )

multipanel_plot


# 4. Save the final aligned plot
ggsave(
  filename = "C:/Users/Karl.Fetter/aphid/multipanel_figure3.png", 
  plot = multipanel_plot, 
  width = 12, 
  height = 7.5, 
  units = "in", 
  dpi = 300
)

ggsave(
  filename = "C:/Users/Karl.Fetter/aphid/multipanel_figure3_12x9.png", 
  plot = multipanel_plot, 
  width = 12, 
  height = 9, 
  units = "in", 
  dpi = 300
)


# Save as Pdf
ggsave(
  filename = "C:/Users/Karl.Fetter/aphid/multipanel_figure3.pdf", 
  plot = multipanel_plot, 
  device = cairo_pdf,  # Forces the high-fidelity Cairo vector engine
  width = 12, 
  height = 7.5, 
  units = "in"
)


