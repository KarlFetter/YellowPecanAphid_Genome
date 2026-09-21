library(tidyverse)

# ====================================================================
# STEP 1: CONFIGURATION
# ====================================================================

data_dir   <- "C:/Users/Karl.Fetter/aphid/coverage/ypa_coverage_stats/data"
figures_dir <- "C:/Users/Karl.Fetter/aphid/coverage/ypa_coverage_stats/figures"

unlogged_output_dir <- file.path(figures_dir, "unlogged_axis")
logged_output_dir   <- file.path(figures_dir, "logged_axis")

dir.create(unlogged_output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(logged_output_dir, recursive = TRUE, showWarnings = FALSE)

col_names <- c("Chromosome", "Start", "End", "Mean_Depth")
assemblies <- c("hap1", "hap2", "primary")
data_types <- c("hifi", "ont")

primary_chromosome_map <- c(
  "ptg000001l_1" = "chr1",
  "ptg000004l_1" = "chr2",
  "ptg000003l_1" = "chr3",
  "ptg000002l_1" = "chr4",
  "ptg000005l_1" = "chr5",
  "ptg000006l_1" = "chr6"
)

# ====================================================================
# STEP 2: HELPER FUNCTIONS
# ====================================================================

# Build the input filepath for one assembly and read type.
build_input_path <- function(assembly, data_type) {
  file.path(data_dir, paste0("ypa_", assembly, "_", data_type, "_100kb_coverage.txt"))
}

# Safely load coverage file; returns tibble with expected columns + Source
# If file missing/empty/unreadable, returns empty tibble with correct columns.
safe_read_coverage <- function(file_path, source_label) {
  empty_tbl <- tibble(
    Chromosome = character(),
    Start = numeric(),
    End = numeric(),
    Mean_Depth = numeric(),
    Source = character()
  )
  
  if (!file.exists(file_path)) {
    message("Missing file: ", file_path)
    return(empty_tbl)
  }
  
  info <- file.info(file_path)
  if (is.na(info$size) || info$size == 0) {
    message("Empty file: ", file_path)
    return(empty_tbl)
  }
  
  out <- tryCatch(
    {
      read_tsv(file_path, col_names = col_names, show_col_types = FALSE) %>%
        mutate(Source = source_label)
    },
    error = function(e) {
      message("Read error in ", file_path, " -> ", e$message)
      empty_tbl
    }
  )
  
  out
}

# Return primary chromosomes in biological order or all haplotype scaffolds by size.
get_plot_chromosomes <- function(df, assembly) {
  if (nrow(df) == 0) return(character())
  
  if (assembly == "primary") {
    return(names(primary_chromosome_map)[names(primary_chromosome_map) %in% df$Chromosome])
  }
  
  df %>%
    group_by(Chromosome) %>%
    summarize(Total_Size_bp = max(End, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(Total_Size_bp)) %>%
    pull(Chromosome)
}

get_plot_dimensions <- function(assembly) {
  if (assembly == "primary") {
    c(width = 12, height = 8)
  } else {
    c(width = 8, height = 10)
  }
}

# Placeholder plot when no data exists
make_no_data_plot <- function(title_text, subtitle_text = "No data available for this selection") {
  ggplot() +
    annotate("text", x = 0, y = 0, label = "No data available", size = 8, fontface = "bold") +
    xlim(-1, 1) +
    ylim(-1, 1) +
    labs(
      title = title_text,
      subtitle = subtitle_text,
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_size = 12) +
    theme(
      axis.text = element_blank(),
      axis.ticks = element_blank(),
      panel.grid = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "gray30")
    )
}

# Save PNG with explicit white background
save_png <- function(plot_obj, out_path, width = 12, height = 8, dpi = 300) {
  plot_with_white_bg <- plot_obj +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      legend.background = element_rect(fill = "white", color = NA),
      legend.box.background = element_rect(fill = "white", color = NA)
    )
  
  ggsave(
    filename = out_path,
    plot = plot_with_white_bg,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
  
  message("Saved: ", out_path)
}

# ====================================================================
# STEP 3: PLOT BUILDERS (UNLOGGED) - UPDATED Y-AXIS LIMITS
# ====================================================================
make_single_plot <- function(df, assembly, data_type, top_n = 12) {
  title_text <- paste("Read coverage:", ifelse(data_type == "hifi", "HiFi", "ONT"),
                      "-", assembly, "assembly")
  subtitle_text <- if (assembly == "primary") {
    "Coverage calculated from 100 Kb windows"
  } else {
    "Scaffolds sorted by size. Coverage calculated from 100 Kb windows."
  }
  
  if (nrow(df) == 0) {
    return(make_no_data_plot(title_text, subtitle_text))
  }
  
  top_chrs <- get_plot_chromosomes(df, assembly)
  if (length(top_chrs) == 0) {
    return(make_no_data_plot(title_text, subtitle_text))
  }
  
  plot_df <- df %>%
    filter(Chromosome %in% top_chrs) %>%
    mutate(
      Chromosome = factor(Chromosome, levels = top_chrs,
                          labels = if (assembly == "primary") {
                            unname(primary_chromosome_map[top_chrs])
                          } else {
                            top_chrs
                          }),
      Position_Mb = Start / 1e6
    )
  
  ggplot(plot_df, aes(x = Position_Mb, y = Mean_Depth)) +
    geom_line(color = "#2C7FB8", alpha = 0.85, linewidth = 0.4) +
    facet_wrap(~ Chromosome, scales = "free_x", ncol = 2) +
    coord_cartesian(ylim = c(0, 300)) + # Caps y-axis at 300 without discarding data
    theme_minimal(base_size = 11) +
    labs(
      title = title_text,
      subtitle = subtitle_text,
      x = "Genomic Position (Mb)",
      y = "Mean Depth"
    ) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "gray30"),
      strip.text = element_text(face = "bold", size = 9),
      panel.grid.minor = element_blank()
    )
}

make_merged_plot <- function(df_merged, assembly, top_n = 12) {
  title_text <- paste("Read coverage comparison: HiFi vs ONT -", assembly, "assembly")
  subtitle_text <- if (assembly == "primary") {
    "Coverage calculated from 100 Kb windows"
  } else {
    "Scaffolds sorted by size. Coverage calculated from 100 Kb windows."
  }
  
  if (nrow(df_merged) == 0) {
    return(make_no_data_plot(title_text, subtitle_text))
  }
  
  top_chrs <- get_plot_chromosomes(df_merged, assembly)
  if (length(top_chrs) == 0) {
    return(make_no_data_plot(title_text, subtitle_text))
  }
  
  plot_df <- df_merged %>%
    filter(Chromosome %in% top_chrs) %>%
    mutate(
      Chromosome = factor(Chromosome, levels = top_chrs,
                          labels = if (assembly == "primary") {
                            unname(primary_chromosome_map[top_chrs])
                          } else {
                            top_chrs
                          }),
      Position_Mb = Start / 1e6
    )
  
  ggplot(plot_df, aes(x = Position_Mb, y = Mean_Depth, color = Source)) +
    geom_line(alpha = 0.8, linewidth = 0.45) +
    facet_wrap(~ Chromosome, scales = "free_x", ncol = 2) +
    coord_cartesian(ylim = c(0, 300)) + # Caps y-axis at 300 without discarding data
    scale_color_brewer(palette = "Set1", name = "Data Type") +
    theme_minimal(base_size = 11) +
    labs(
      title = title_text,
      subtitle = subtitle_text,
      x = "Genomic Position (Mb)",
      y = "Mean Depth"
    ) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "gray30"),
      strip.text = element_text(face = "bold", size = 9),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}



# ====================================================================
# STEP 4: PLOT BUILDERS (LOGGED Y AXIS)
# ====================================================================

make_single_plot_log <- function(df, assembly, data_type, top_n = 12) {
  title_text <- paste("Read coverage (log Y):", ifelse(data_type == "hifi", "HiFi", "ONT"),
                      "-", assembly, "assembly")
  subtitle_text <- if (assembly == "primary") {
    "Coverage calculated from 100 Kb windows"
  } else {
    "Scaffolds sorted by size. Coverage calculated from 100 Kb windows."
  }
  
  if (nrow(df) == 0) {
    return(make_no_data_plot(title_text, subtitle_text))
  }
  
  top_chrs <- get_plot_chromosomes(df, assembly)
  if (length(top_chrs) == 0) {
    return(make_no_data_plot(title_text, subtitle_text))
  }
  
  plot_df <- df %>%
    filter(Chromosome %in% top_chrs) %>%
    mutate(
      Chromosome = factor(Chromosome, levels = top_chrs,
                          labels = if (assembly == "primary") {
                            unname(primary_chromosome_map[top_chrs])
                          } else {
                            top_chrs
                          }),
      Position_Mb = Start / 1e6,
      Mean_Depth = as.numeric(Mean_Depth)
    ) %>%
    filter(!is.na(Mean_Depth), Mean_Depth > 0)
  
  if (nrow(plot_df) == 0) {
    return(make_no_data_plot(title_text, "No positive Mean_Depth values for log scale"))
  }
  
  ggplot(plot_df, aes(x = Position_Mb, y = Mean_Depth)) +
    geom_line(color = "#2C7FB8", alpha = 0.85, linewidth = 0.4) +
    facet_wrap(~ Chromosome, scales = "free_x", ncol = 2) +
    scale_y_log10() +
    theme_minimal(base_size = 11) +
    labs(
      title = title_text,
      subtitle = subtitle_text,
      x = "Genomic Position (Mb)",
      y = "Mean Depth (log10 scale)"
    ) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "gray30"),
      strip.text = element_text(face = "bold", size = 9),
      panel.grid.minor = element_blank()
    )
}

make_merged_plot_log <- function(df_merged, assembly, top_n = 12) {
  title_text <- paste("Read coverage comparison (log Y): HiFi vs ONT -", assembly, "assembly")
  subtitle_text <- if (assembly == "primary") {
    "Coverage calculated from 100 Kb windows"
  } else {
    "Scaffolds sorted by size. Coverage calculated from 100 Kb windows."
  }
  
  if (nrow(df_merged) == 0) {
    return(make_no_data_plot(title_text, subtitle_text))
  }
  
  top_chrs <- get_plot_chromosomes(df_merged, assembly)
  if (length(top_chrs) == 0) {
    return(make_no_data_plot(title_text, subtitle_text))
  }
  
  plot_df <- df_merged %>%
    filter(Chromosome %in% top_chrs) %>%
    mutate(
      Chromosome = factor(Chromosome, levels = top_chrs,
                          labels = if (assembly == "primary") {
                            unname(primary_chromosome_map[top_chrs])
                          } else {
                            top_chrs
                          }),
      Position_Mb = Start / 1e6,
      Mean_Depth = as.numeric(Mean_Depth)
    ) %>%
    filter(!is.na(Mean_Depth), Mean_Depth > 0)
  
  if (nrow(plot_df) == 0) {
    return(make_no_data_plot(title_text, "No positive Mean_Depth values for log scale"))
  }
  
  ggplot(plot_df, aes(x = Position_Mb, y = Mean_Depth, color = Source)) +
    geom_line(alpha = 0.8, linewidth = 0.45) +
    facet_wrap(~ Chromosome, scales = "free_x", ncol = 2) +
    scale_y_log10() +
    scale_color_brewer(palette = "Set1", name = "Data Type") +
    theme_minimal(base_size = 11) +
    labs(
      title = title_text,
      subtitle = subtitle_text,
      x = "Genomic Position (Mb)",
      y = "Mean Depth (log10 scale)"
    ) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "gray30"),
      strip.text = element_text(face = "bold", size = 9),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

# ====================================================================
# STEP 5: GENERATE UNLOGGED OUTPUTS
# ====================================================================

# 6 single-source unlogged plots
for (assembly in assemblies) {
  for (data_type in data_types) {
    in_path <- build_input_path(assembly, data_type)
    source_label <- ifelse(data_type == "hifi", "HiFi", "ONT")
    df <- safe_read_coverage(in_path, source_label = source_label)
    
    p <- make_single_plot(df, assembly = assembly, data_type = data_type, top_n = 12)
    
    out_name <- paste0("ypa_", assembly, "_", data_type, "_coverage_profile.png")
    out_path <- file.path(unlogged_output_dir, out_name)
    dimensions <- get_plot_dimensions(assembly)
    save_png(p, out_path, width = dimensions[["width"]], height = dimensions[["height"]])
  }
}

# 3 merged unlogged plots
for (assembly in assemblies) {
  hifi_path <- build_input_path(assembly, "hifi")
  ont_path  <- build_input_path(assembly, "ont")
  
  df_hifi <- safe_read_coverage(hifi_path, source_label = "HiFi")
  df_ont  <- safe_read_coverage(ont_path, source_label = "ONT")
  df_merged <- bind_rows(df_hifi, df_ont)
  
  p_merged <- make_merged_plot(df_merged, assembly = assembly, top_n = 12)
  
  out_name <- paste0("ypa_", assembly, "_hifi_vs_ont_coverage_profile.png")
  out_path <- file.path(unlogged_output_dir, out_name)
  dimensions <- get_plot_dimensions(assembly)
  save_png(p_merged, out_path, width = dimensions[["width"]], height = dimensions[["height"]])
}

# ====================================================================
# STEP 6: GENERATE LOGGED OUTPUTS
# ====================================================================

# 6 single-source logged plots
for (assembly in assemblies) {
  for (data_type in data_types) {
    in_path <- build_input_path(assembly, data_type)
    source_label <- ifelse(data_type == "hifi", "HiFi", "ONT")
    df <- safe_read_coverage(in_path, source_label = source_label)
    
    p_log <- make_single_plot_log(df, assembly = assembly, data_type = data_type, top_n = 12)
    
    out_name_log <- paste0("ypa_", assembly, "_", data_type, "_coverage_profile_LOGY.png")
    out_path_log <- file.path(logged_output_dir, out_name_log)
    dimensions <- get_plot_dimensions(assembly)
    save_png(p_log, out_path_log, width = dimensions[["width"]], height = dimensions[["height"]])
  }
}

# 3 merged logged plots
for (assembly in assemblies) {
  hifi_path <- build_input_path(assembly, "hifi")
  ont_path  <- build_input_path(assembly, "ont")
  
  df_hifi <- safe_read_coverage(hifi_path, source_label = "HiFi")
  df_ont  <- safe_read_coverage(ont_path, source_label = "ONT")
  df_merged <- bind_rows(df_hifi, df_ont)
  
  p_merged_log <- make_merged_plot_log(df_merged, assembly = assembly, top_n = 12)
  
  out_name_log <- paste0("ypa_", assembly, "_hifi_vs_ont_coverage_profile_LOGY.png")
  out_path_log <- file.path(logged_output_dir, out_name_log)
  dimensions <- get_plot_dimensions(assembly)
  save_png(p_merged_log, out_path_log, width = dimensions[["width"]], height = dimensions[["height"]])
}

message("All plotting tasks completed.")