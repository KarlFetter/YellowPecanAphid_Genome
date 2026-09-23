#!/usr/bin/env Rscript

# Define file paths
input_file <- "/90daydata/tgl_seqdata/aphids/assembly/ypa/04_assembly/CoveragePlot_Hifiasm_UL/hifiasm_rounds_coverage.csv"
out_dir    <- "/90daydata/tgl_seqdata/aphids/assembly/ypa/04_assembly/CoveragePlot_Hifiasm_UL"

# Define file paths
setwd("C:/Users/Karl.Fetter/aphid/CoveragePlot_Hifiasm_UL")
input_file <- "hifiasm_rounds_coverage.csv"
out_dir <- "C:/Users/Karl.Fetter/aphid/CoveragePlot_Hifiasm_UL"

# 1. Read the dataset using Base R's native CSV reader
df <- read.csv(input_file)

# 2. Filter data window to clear low-coverage tails (subsetting coverages 5 to 220)
plot_data <- subset(df, Coverage >= 5 & Coverage <= 220)

# High-contrast colors for the assembly rounds
colors <- c("Round_1"="#e74c3c", "Round_2"="#3498db", "Round_3"="#2ecc71", "Round_4"="#f1c40f")

# --- FIGURE 1: 5 Lines Only (Compact 3" x 3") ---
png(file.path(out_dir, "hifiasm_4rounds_only.png"), width = 3, height = 3, units = "in", res = 300)
# Set up tight margins to make the compact figure publication-ready
par(mar = c(3.5, 3.5, 1, 1), mgp = c(2, 0.7, 0), cex.axis = 0.8, cex.lab = 0.9)

# Initialize blank plot frame matching data coordinates
plot(plot_data$Coverage, plot_data$Round_1, type = "n",
     xlab = "Coverage", ylab = "Count", ylim = c(0, max(plot_data[, 2:6])))

# Draw the 5 individual trace lines sequentially
lines(plot_data$Coverage, plot_data$Round_1, col = colors["Round_1"], lwd = 0.8)
lines(plot_data$Coverage, plot_data$Round_2, col = colors["Round_2"], lwd = 0.8)
lines(plot_data$Coverage, plot_data$Round_3, col = colors["Round_3"], lwd = 0.8)
lines(plot_data$Coverage, plot_data$Round_4, col = colors["Round_4"], lwd = 0.8)
dev.off()

# --- FIGURE 1: 5 Lines Only (Compact 3" x 3") ---
png(file.path(out_dir, "hifiasm_4rounds_only_lwd3.png"), width = 3, height = 3, units = "in", res = 300)
# Set up tight margins to make the compact figure publication-ready
par(mar = c(3.5, 3.5, 1, 1), mgp = c(2, 0.7, 0), cex.axis = 0.8, cex.lab = 0.9)

# Initialize blank plot frame matching data coordinates
plot(plot_data$Coverage, plot_data$Round_1, type = "n",
     xlab = "Coverage", ylab = "Count", ylim = c(0, max(plot_data[, 2:6])))

# Draw the 5 individual trace lines sequentially
lines(plot_data$Coverage, plot_data$Round_1, col = adjustcolor(colors["Round_1"], alpha.f=0.8), lwd = 3)
lines(plot_data$Coverage, plot_data$Round_2, col = adjustcolor(colors["Round_2"], alpha.f=0.8), lwd = 3)
lines(plot_data$Coverage, plot_data$Round_3, col = adjustcolor(colors["Round_3"], alpha.f=0.8), lwd = 3)
lines(plot_data$Coverage, plot_data$Round_4, col = adjustcolor(colors["Round_4"], alpha.f=0.8), lwd = 3)
dev.off()


# --- FIGURE 2: 5 Lines + Thick Solid Average Line (Compact 3" x 3") ---
png(file.path(out_dir, "hifiasm_rounds_with_average.png"), width = 3, height = 3, units = "in", res = 300)
par(mar = c(3.5, 3.5, 1, 1), mgp = c(2, 0.7, 0), cex.axis = 0.8, cex.lab = 0.9)

# Initialize plot frame
plot(plot_data$Coverage, plot_data$Round_1, type = "n",
     xlab = "Coverage", ylab = "Count", ylim = c(0, max(plot_data[, 2:6])))

# Draw the 5 underlying rounds with a lighter thin line
lines(plot_data$Coverage, plot_data$Round_1, col = colors["Round_1"], lwd = 0.5, lty = 1)
lines(plot_data$Coverage, plot_data$Round_2, col = colors["Round_2"], lwd = 0.5, lty = 1)
lines(plot_data$Coverage, plot_data$Round_3, col = colors["Round_3"], lwd = 0.5, lty = 1)
lines(plot_data$Coverage, plot_data$Round_4, col = colors["Round_4"], lwd = 0.5, lty = 1)

# Overlay the bold, thicker global mean average line on top
lines(plot_data$Coverage, plot_data$Average, col = "#2c3e50", lwd = 2.0)
dev.off()

print("Both 3x3 Base R publication figures successfully written to the directory.")



