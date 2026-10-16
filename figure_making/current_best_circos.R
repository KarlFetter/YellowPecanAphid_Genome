
setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)

#library(circlize)
#library(tidyverse)

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
gene <- read.csv(gene_track, header = TRUE, stringsAsFactors = FALSE) %>%
  slice_sample(prop = 0.10)  # Temporary thining. Delete when ready.

colnames(karyotype) <- c("chr", "start", "end")
colnames(snps)      <- c("chr", "start", "end", "count")

snps$count       <- as.numeric(as.character(snps$count))
rep1$start       <- as.numeric(as.character(rep1$start))
rep1$end         <- as.numeric(as.character(rep1$end))
rep1$repeat_size <- as.numeric(as.character(rep1$repeat_size))

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
circos.clear()

#pdf("ypa_circos_2track_v1.pdf", width = 8, height = 8)
#png("ypa_circos_2track_v0.png", width = 850, height = 850)
#jpeg("ypa_circos_2track_v0.jpeg", width = 850, height = 850, quality = 90)

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

# Track 3: gene locations as short bars.
circos.track(sectors = gene$chr, x = gene$start, y = rep(0.5, nrow(gene)),
             ylim = c(0, 1), track.height = 0.09,
             bg.col = "#FFFFFF", bg.border = NA,
             track.margin = c(0, 0.01), # add a hair of space above track
             panel.fun = function(x, y) {
               # baseline shelf so the gene bars sit on a visible track
               circos.rect(CELL_META$xlim[1], 0.08, CELL_META$xlim[2], 0.28,
                           col = "grey60", border = "black", lwd = 0.3)
               
               chr_len <- CELL_META$xlim[2]
               minor_ticks <- seq(0, chr_len, by = 10000000)  # every 10 Mb, adjust as needed
               
               for (tick in minor_ticks) {
                 circos.segments(tick, 0.08, tick, 0.28,
                                 col = "grey20", lwd = 0.5)
               }
               
               label_ticks <- seq(0, chr_len, by = 20000000)  # thin labels to every 20 Mb
               # Mb labels disabled - overlapped the chr box regardless of position
               # circos.text(label_ticks, rep(0.005, length(label_ticks)),
               #             paste0(label_ticks / 1000000, "Mb"),
               #             cex = 0.45, col = "black",
               #             facing = "clockwise", niceFacing = TRUE)
               
               sector_gene <- gene[gene$chr == CELL_META$sector.index, ]
               
               circos.rect(sector_gene$start, 0.28,
                           sector_gene$end, 1,
                           col = "#2C3E50", border = NA)
               
               draw_sector_edges(lwd = 0.15, inset = 0.05)
             })

# Run this manually before redrawing:
#dev.off()
#circos.clear()
