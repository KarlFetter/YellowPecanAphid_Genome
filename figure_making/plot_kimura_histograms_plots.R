#!/usr/bin/env Rscript
library(ggplot2)
library(tidyr)
library(dplyr)
library(stringr)

# 1. Read the wide data matrix
df <- read.table("ypa_wide_landscape.txt", header = TRUE, check.names = FALSE)

# Define genome size for y-axis percentage calculation
GENOME_SIZE <- 509312744

# 2. Reshape data and apply your exact structural category groupings
plot_data <- df %>%
  pivot_longer(cols = -Div, names_to = "SubClass", values_to = "Base_Count") %>%
  mutate(
    FinalClass = case_when(
      str_detect(SubClass, "^DNA/") | SubClass == "DNA" ~ "DNA Transposon",
      str_detect(SubClass, "^LINE|^LTR|^SINE")         ~ "Retrotransposon",
      str_detect(SubClass, "^RC/")                     ~ "Rolling Circles",
      str_detect(SubClass, "^Satellite")               ~ "Satellites",
      str_detect(SubClass, "^Simple_repeat")           ~ "Simple Repeats",
      str_detect(SubClass, "^Unknown|^Unspecified")     ~ "Unclassified",
      TRUE                                             ~ "Unclassified"
    )
  ) %>%
  # Aggregate counts based on the new broad categories
  group_by(Div, FinalClass) %>%
  summarise(Total_Bases = sum(Base_Count), .groups = 'drop') %>%
  mutate(Genome_Percent = (Total_Bases / GENOME_SIZE) * 100)

# 3. Define a manual, highly distinct color palette with a grey baseline for Unclassified
#color_palette <- c(
#  "DNA Transposon"  = "#E41A1C", # Bold Red
#  "Retrotransposon" = "#377EB8", # Clear Blue
#  "Rolling Circles" = "#4DAF4A", # Vibrant Green
#  "Satellites"      = "#984EA3", # Deep Purple
#  "Simple Repeats"  = "#FF7F00", # Bright Orange
#  "Unclassified"    = "#999999"  # Neutral Grey
#)

# Define a colorblind-friendly manual palette (using Okabe-Ito colors with grey)
color_palette <- c(
  "DNA Transposon"  = "#56B4E9", # Sky Blue
  "Retrotransposon" = "#E69F00", # Orange
  "Rolling Circles" = "#009E73", # Bluish Green
  "Satellites"      = "#CC79A7", # Reddish Purple
  "Simple Repeats"  = "#0072B2", # Blue
  "Unclassified"    = "#999999"  # Neutral Grey
)

# 4. Generate the Stacked Landscape Plot
landscape_plot <- ggplot(plot_data, aes(x = Div, y = Genome_Percent, fill = FinalClass)) +
  geom_bar(stat = "identity", width = 1, position = "stack") +
  scale_x_continuous(limits = c(-1, 51), breaks = seq(0, 50, 5)) +
  scale_fill_manual(values = color_palette) + 
  labs(
    title = "Interspersed Repeat Landscape",
    x = "Kimura substitution level (CpG adjusted)",
    y = "percent of genome",
    fill = "Repeat Type"
  ) +
  theme_minimal() +
  theme(
    text = element_text(size = 12),
    plot.title = element_text(hjust = 0.05, face = "bold", size = 14),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    axis.line = element_line(color = "black"),
    legend.position = "right"
  )

# 5. Save output image
ggsave("ypa_top6_simplified_landscape.png", plot = landscape_plot, width = 6, height = 4, dpi = 300)

