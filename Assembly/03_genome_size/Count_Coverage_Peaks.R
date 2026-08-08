#!/usr/bin/env Rscript

# 1. Load data (assuming space or tab-separated without headers)
# Column 1 = Coverage, Column 2 = K-mer Count
data <- read.table("ypa_k21.histo", col.names = c("coverage", "count"))

# 2. Filter out the massive sequencing error tail at the beginning
# We start scanning after 15x coverage to avoid finding the error drop-off
clean_data <- subset(data, coverage >= 15 & coverage <= 400)

# 3. Smooth the counts using a rolling average to eliminate random noise
# Using a window size of 5 handles local fluctuations cleanly
smoothed_counts <- filter(clean_data$count, rep(1/5, 5), sides = 2)

# 4. Find local peaks (where a point is higher than its neighbors)
peaks <- which(diff(sign(diff(smoothed_counts))) == -2) + 1

# 5. Extract the real coverage coordinates for the peaks
peak_coverages <- clean_data$coverage[peaks]
peak_counts <- clean_data$count[peaks]

# 6. Combine and print the results
results <- data.frame(Peak = 1:length(peak_coverages), 
                      Coverage_X = peak_coverages, 
                      Kmer_Count = peak_counts)

print("--- Identified GenomeScope K-mer Peaks ---")
print(results)
