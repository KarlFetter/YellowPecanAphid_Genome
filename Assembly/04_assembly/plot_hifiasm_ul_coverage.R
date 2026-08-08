library(tidyverse)

# Define file paths
setwd("C:/Users/Karl.Fetter/aphid/CoveragePlot_Hifiasm_UL")
input_file <- "hifiasm_rounds_coverage.csv"
out_dir <- "C:/Users/Karl.Fetter/aphid/CoveragePlot_Hifiasm_UL"

# Define file paths
#input_file <- "/90daydata/tgl_seqdata/aphids/assembly/ypa/04_assembly/CoveragePlot_Hifiasm_UL/hifiasm_rounds_coverage.csv"
#out_dir    <- "/90daydata/tgl_seqdata/aphids/assembly/ypa/04_assembly/CoveragePlot_Hifiasm_UL"

# 1. Read data table using stable Base R CSV parser
raw_df <- read.csv(input_file)

# 2. Tidyverse data wrangling loop
# Filter the coverage range and transform columns from wide to long format for ggplot
plot_data <- raw_df %>%
  filter(Coverage >= 5 & Coverage <= 220)

long_data <- plot_data %>%
  pivot_longer(
    cols = starts_with("Round_"), 
    names_to = "Round", 
    values_to = "Count"
  )

# Define clean high-contrast hex colors matching your aesthetic specifications
round_palette <- c("#e74c3c", "#3498db", "#2ecc71", "#f1c40f", "#9b59b6")

# --- FIGURE 1: 5 Lines Only (Compact 3" x 3") ---
p1 <- ggplot(long_data, aes(x = Coverage, y = Count, color = Round)) +
  geom_line(linewidth = 0.4, alpha = 0.9) +
  scale_color_manual(values = round_palette) +
  theme_bw(base_size = 8) +
  labs(x = "Coverage", y = "Count") +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.margin = margin(1, 1, 1, 1, "mm")
  )

ggsave(
  filename = file.path(out_dir, "hifiasm_5rounds_only.png"), 
  plot = p1, 
  width = 3, 
  height = 3, 
  dpi = 300,
  units = "in"
)

# --- FIGURE 2: 5 Lines + Solid Thicker Average Line (Compact 3" x 3") ---
p2 <- ggplot() +
  # 5 individual fine-line trace vectors
  geom_line(data = long_data, aes(x = Coverage, y = Count, color = Round), linewidth = 0.3, alpha = 0.5) +
  # Single bold overlay tracking the global mean average column matrix
  geom_line(data = plot_data, aes(x = Coverage, y = Average), color = "#2c3e50", linewidth = 0.9) +
  scale_color_manual(values = round_palette) +
  theme_bw(base_size = 8) +
  labs(x = "Coverage", y = "Count") +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.margin = margin(1, 1, 1, 1, "mm")
  )

ggsave(
  filename = file.path(out_dir, "hifiasm_rounds_with_average.png"), 
  plot = p2, 
  width = 3, 
  height = 3, 
  dpi = 300,
  units = "in"
)

print("Both compact 3x3 tidyverse/ggplot2 figures successfully generated inside CoveragePlot_Hifiasm_UL/")
