library(ggplot2)
library(dplyr)
library(stringr)

# 1. Load Data
df <- read.csv("ypa_primary_top6.fa.out.csv", header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)

# Quick fix of duplicate name
names(df)[12] <- "position_in_repeat_begin"

# 2. Define the exact chromosome mapping and structural order layout
chrom_order <- c(
  "ptg000001l_1" = "Chr01",
  "ptg000004l_1" = "Chr02",
  "ptg000003l_1" = "Chr03",
  "ptg000002l_1" = "Chr04",
  "ptg000005l_1" = "Chr05",
  "ptg000006l_1" = "Chr06"
)

# 3. Standardize repeat taxonomy.
plot_data <- df %>%
  filter(query_sequence %in% names(chrom_order)) %>%
  mutate(
    # Compute length of each feature insertion entry
    BP_Length = abs(position_in_query_end - position_in_query_begin) + 1,
    
    # Collapse detailed subcategories into six broad categories.
    Order = case_when(
      str_detect(rep_class, "^DNA") ~ "DNA Transposon",
      str_detect(rep_class, "^LINE|^LTR|^SINE|^PLE") ~ "Retrotransposon",
      str_detect(rep_class, "^RC/") ~ "Rolling Circles",
      str_detect(rep_class, "^Satellite") ~ "Satellites",
      str_detect(rep_class, "^Simple_repeat") ~ "Simple Repeats",
      str_detect(rep_class, "^Low_complexity") ~ "Low Complexity",
      str_detect(rep_class, "^Unknown|^Unspecified") ~ "Unclassified",
      TRUE ~ "Unclassified"
    ),
    
    # Set vertical alignment order so Chr01 sits cleanly at the top of the plot grid
    CHROM = factor(chrom_order[query_sequence], levels = rev(chrom_order))
  ) %>%
  # Aggregate raw base counts into total Megabases
  group_by(CHROM, Order) %>%
  summarise(Total_Megabases = sum(BP_Length) / 1e6, .groups = 'drop') %>%
  
  # Structural lock on categorical display order to match the legend
  mutate(Order = factor(Order, levels = c(
    "DNA Transposon", "Low Complexity", "Retrotransposon", 
    "Rolling Circles", "Satellites", "Simple Repeats", "Unclassified"
  )))

# 4. Map colors to repeat categories.
color_palette <- c(
  "DNA Transposon"  = "#56B4E9", # Sky Blue
  "Low Complexity"  = "#F0E442", # Yellow
  "Retrotransposon" = "#E69F00", # Orange
  "Rolling Circles" = "#009E73", # Bluish Green
  "Satellites"      = "#CC79A7", # Reddish Purple
  "Simple Repeats"  = "#0072B2", # Blue
  "Unclassified"    = "#999999"  # Neutral Grey
)

# =========================================================================
# PLOT 1: Standard Horizontal Barplot (Total Repeat content in Mb)
# =========================================================================
p_standard_bar <- ggplot(plot_data, aes(x = Total_Megabases, y = CHROM)) +
  geom_bar(stat = "identity", fill = "#5b6976", color = "white", linewidth = 0.2, alpha = 0.9) +
  labs(
    x = "Total Sequence (Mb)",
    y = "Chromosome",
    title = "Total Interspersed Repeat Content per Chromosome"
  ) +
  theme_bw(base_size = 14) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.border = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.6),
    axis.text = element_text(color = "black")
  )
p_standard_bar

# =========================================================================
# PLOT 2: Stacked Horizontal Barplot (By Order Category)
# =========================================================================
p_stacked_bar <- ggplot(plot_data, aes(x = Total_Megabases, y = CHROM, fill = Order)) +
  geom_bar(stat = "identity", position = "stack", color = "white", linewidth = 0.1) +
  scale_fill_manual(values = color_palette, name = "Repeat Type") +
  labs(
    x = "Total Sequence (Mb)",
    y = "Chromosome",
    title = "Repeat Class Distribution Across Chromosomes"
  ) +
  theme_bw(base_size = 14) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.border = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.6),
    axis.text = element_text(color = "black"),
    legend.position = "right"
  )
p_stacked_bar

# =========================================================================
# PLOT 3: Stacked Horizontal Barplot (By Order Category) Modified
# =========================================================================
p_stacked_bar <- ggplot(plot_data, aes(x = Total_Megabases, y = CHROM, fill = Order)) +
  geom_bar(stat = "identity", position = "stack", color = "white", linewidth = 0.1) +
  scale_fill_manual(values = color_palette, name = "Repeat Type") +
  labs(
    x = "Total Sequence (Mb)",
    y = "Chromosome",
    ) +
  theme_bw(base_size = 24) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#f0f0f0"),
    panel.border = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.6),
    axis.text = element_text(color = "black"),
    legend.position = "none"
  )
p_stacked_bar

# Save output plots as clean high-fidelity vector graphics
ggsave("chrom_repeat_totals.pdf", plot = p_standard_bar, width = 7, height = 4, device = cairo_pdf)

ggsave("chrom_repeat_stacked.pdf", 
       plot = p_stacked_bar, 
       width = 8,
       height = 4, 
       device = cairo_pdf)


ggsave("chrom_repeat_stacked.png", 
       plot = p_stacked_bar, 
       width = 5,
       height = 7, 
       dpi = 300)
