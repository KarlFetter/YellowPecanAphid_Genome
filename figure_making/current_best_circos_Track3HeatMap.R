# Production Code Used to Make Circos Plot

setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)

library(circlize)
library(dplyr)

# ----------------------------------------------------
# 1. DATA LOADING
# ----------------------------------------------------
setwd("C:/Users/Karl.Fetter/aphid/circos")

genome_main   <- "general_chromosome_map.csv"
snp_track     <- "ypa_snp_density_10kb.csv"
repeat_track1 <- "repeat_size_RepClass_Filter50bp.csv"
gene_track    <- "gene_track.csv"

karyotype <- read.csv(genome_main, header = TRUE, stringsAsFactors = FALSE)
snps      <- read.csv(snp_track, header = FALSE, stringsAsFactors = FALSE)
rep1      <- read.csv(repeat_track1, header = TRUE, stringsAsFactors = FALSE)
gene      <- read.csv(gene_track, header = TRUE, stringsAsFactors = FALSE)

colnames(karyotype) <- c("chr", "start", "end")
colnames(snps)      <- c("chr", "start", "end", "count")

snps$count       <- as.numeric(as.character(snps$count))
rep1$start       <- as.numeric(as.character(rep1$start))
rep1$end         <- as.numeric(as.character(rep1$end))
rep1$repeat_size <- as.numeric(as.character(rep1$repeat_size))

# ----------------------------------------------------
# 1b. GENE DENSITY TRACK
# ----------------------------------------------------
gene <- read.csv(gene_track, header = TRUE, stringsAsFactors = FALSE) %>%
  mutate(
    start = as.numeric(start),
    end = as.numeric(end)
  ) #%>%
  #slice_sample(prop = 0.10)

# ----------------------------------------------------
# 2. COLORS AND AXIS SETTINGS
# ----------------------------------------------------
full_color_palette <- c(
  "DNA_transposon"  = "#56B4E9",
  "DNA Transposon"  = "#56B4E9",
  "Low_complexity"  = "#F0E442",
  "Low Complexity"  = "#F0E442",
  "Retrotransposon" = "#E69F00",
  "Rolling_Circle"  = "#009E73",
  "Rolling Circles" = "#009E73",
  "Satellite"       = "#CC79A7",
  "Satellites"      = "#CC79A7",
  "Simple_repeat"   = "#0072B2",
  "Simple Repeats"  = "#0072B2",
  "unclassified"    = "grey60",
  "Unclassified"    = "grey60"
)

rep1$point_color <- full_color_palette[rep1$repeat_type]
rep1$point_color[is.na(rep1$point_color)] <- "#000000"

max_snp  <- max(snps$count, na.rm = TRUE)
max_rep1 <- 10000

snp_ticks  <- pretty(c(0, max_snp), n = 3)
rep1_ticks <- c(0, 2500, 5000, 7500, 10000)

draw_sector_edges <- function(col = "black", lwd = 0.15, inset = 0.15) {
  y0 <- CELL_META$ylim[1] + diff(CELL_META$ylim) * inset
  y1 <- CELL_META$ylim[2] - diff(CELL_META$ylim) * inset
  
  circos.segments(CELL_META$xlim[1], y0,
                  CELL_META$xlim[1], y1,
                  col = col, lwd = lwd)
  circos.segments(CELL_META$xlim[2], y0,
                  CELL_META$xlim[2], y1,
                  col = col, lwd = lwd)
}

# ----------------------------------------------------
# 3. BUILD THE FIGURE
# ----------------------------------------------------
# wrapped in a function so it can be replayed into any device (screen, PNG, PDF)
render_circos_plot <- function() {
  circos.clear()
  
  circos.par(
    start.degree = 90,
    gap.after = c(rep(1.5, length(karyotype$chr) - 1), 10), # controls chr gap size
    cell.padding = c(0, 0, 0, 0),
    track.margin = c(0, 0),
    points.overflow.warning = FALSE
  )
  
  circos.initialize(
    sectors = karyotype$chr,
    xlim = cbind(karyotype$start, karyotype$end)
  )
  
  # Outermost chromosome labels and Mb axis.
  circos.track(sectors = karyotype$chr, ylim = c(0, 1), track.height = 0.12,
               bg.border = NA, track.margin = c(0, 0), panel.fun = function(x, y) {
                 chr_len <- CELL_META$xlim[2]
                 major_ticks <- seq(0, chr_len, by = 10000000)
                 
                 circos.axis(h = 0,
                             major.at = major_ticks,
                             labels = paste0(major_ticks / 1000000, "Mb"),
                             labels.cex = 0.45,
                             major.tick.length = 0.18,
                             labels.facing = "clockwise")
                 
                 circos.text(CELL_META$xcenter, 1.18, CELL_META$sector.index,
                             cex = 0.8, font = 2, niceFacing = TRUE)
                 
                 draw_sector_edges(lwd = 0.15, inset = 0.15)
               })
  
  # Darker grey chromosome ring.
  circos.track(sectors = karyotype$chr, ylim = c(0, 1), track.height = 0.035,
               bg.col = "grey60", bg.border = NA, track.margin = c(0, 0.005),
               panel.fun = function(x, y) {
                 draw_sector_edges(lwd = 0.15, inset = 0.10)
               })
  
  # Track 1: SNP density.
  circos.track(sectors = snps$chr, x = snps$start, y = snps$count,
               ylim = c(0, max_snp), track.height = 0.16,
               bg.col = "#E6E6E6", bg.border = NA, panel.fun = function(x, y) {
                 for (tick in snp_ticks) {
                   circos.lines(CELL_META$xlim, c(tick, tick),
                                col = "#808081", lwd = 0.15)
                 }
                 
                 circos.points(x, y,
                               col = adjustcolor("#1f77b4", alpha.f = 0.65),
                               pch = 16, cex = 0.35)
                 
                 if (CELL_META$sector.index == "chr1") {
                   circos.yaxis(side = "left",
                                at = snp_ticks,
                                labels = snp_ticks,
                                labels.cex = 0.45,
                                labels.niceFacing = FALSE)
                 }
               })
  
  # Track 2: repeat size, colored by repeat_type.
  circos.track(sectors = rep1$chr, x = rep1$start, y = rep1$repeat_size,
               ylim = c(0, max_rep1), track.height = 0.16,
               bg.col = "#F0F0F0", bg.border = NA, 
               track.margin = c(0, 0.01), # add a hair of space above track
               panel.fun = function(x, y) {
                 for (tick in rep1_ticks) {
                   circos.lines(CELL_META$xlim, c(tick, tick),
                                col = "#808080", lwd = 0.15)
                 }
                 
                 sector_rep1 <- rep1[rep1$chr == CELL_META$sector.index, ]
                 
                 circos.points(sector_rep1$start, sector_rep1$repeat_size,
                               col = adjustcolor(sector_rep1$point_color, alpha.f = 0.5),
                               pch = 16, cex = 0.35)
                 
                 if (CELL_META$sector.index == "chr1") {
                   circos.yaxis(side = "left",
                                at = rep1_ticks,
                                labels = rep1_ticks,
                                labels.cex = 0.45,
                                labels.niceFacing = FALSE)
                 }
               })
  
  # Track 3: locations of a reproducible 10% sample of genes.
  circos.track(sectors = gene$chr, x = gene$start,
               y = rep(0.5, nrow(gene)),
               ylim = c(0, 1), track.height = 0.13,
               bg.col = "#FFFFFF", bg.border = NA,
               track.margin = c(0, 0.01),
               panel.fun = function(x, y) {
                 circos.rect(CELL_META$xlim[1], 0,
                             CELL_META$xlim[2], 0.15,
                             col = "grey60",
                             border = "black", lwd = 0.3)
                 
                 chr_len <- CELL_META$xlim[2]
                 minor_ticks <- seq(0, chr_len, by = 10000000)
                 
                 for (tick in minor_ticks) {
                   circos.segments(tick, 0, tick, 0.15,
                                   col = "grey20", lwd = 0.5)
                 }
                 
                 sector_gene <- gene[
                   gene$chr == CELL_META$sector.index,
                 ]
                 
                 circos.rect(sector_gene$start, 0.15,
                             sector_gene$end, 1,
                             col = "#2C3E50",
                             border = NA)
               })
}

# render once for the screen/RStudio plot viewer
render_circos_plot()
circos.clear()

# ----------------------------------------------------
# 4. HIGH-QUALITY PNG EXPORT (zooms in cleanly, good for PowerPoint)
# ----------------------------------------------------
png("ypa_circos_gene_heatmap_v2.png", width = 3000, height = 3000, res = 300)#
render_circos_plot()
dev.off()
circos.clear()
