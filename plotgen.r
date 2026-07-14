library(ggplot2)
library(tidyr)
library(dplyr)
library(forcats)
library(patchwork)
library(extrafont)

# if you have installed a new font run the following command to import it into R
# font_import()

loadfonts(quiet = TRUE) # Load fonts for Linux ubuntu

# --- 1. Settings & File Matching ---
files_all <- Sys.glob("/home/cmp24psl/CRUK/myvirtualenv/Results/2025-11-28_1/outputs/beta_lhs*.csv")
file_nums <- as.numeric(gsub(".*beta_lhs_samples_([0-9]+)\\.csv$", "\\1", files_all))
files <- files_all[file_nums <= 10]
files <- files[order(file_nums[file_nums <= 10])]

# Parameter Map for Simpler Names
columns_map <- c(
    "age.similarity.beta" = "Age homophily beta",
    "sex.similarity.beta" = "Sex homophily beta",
    "education.similarity.beta" = "Education homophily beta",
    "smoking.similarity.beta" = "Smoking homophily beta",
    "vaping.similarity.beta" = "Vaping homophily beta",
    "outdegree.beta" = "Outdegree beta",
    "reciprocity.beta" = "Reciprocity beta",
    "transitive.triples.beta" = "Transitive Triplets beta"
)

# Load data and ensure we only keep the parameters we care about + wave ID
list_data <- lapply(1:length(files), function(i) {
    df <- read.csv(files[i])
    # Subset to only keep matching parameters that exist in this file
    existing_cols <- intersect(names(df), names(columns_map))
    df <- df[, existing_cols, drop = FALSE]
    df$wave <- i
    return(df)
})

# Use bind_rows instead of rbind to handle differing columns gracefully
files_all_combined <- dplyr::bind_rows(list_data)

# --- 2. Palette Setup (Red -> Yellow -> Sky Blue) ---
colours <- c("red", "yellow", "#56B4E9")
my_palette <- colorRampPalette(colours)
cbp1 <- my_palette(10)

plots <- list()

# --- 3. Build Individual Subplots ---
for (i in 1:length(columns_map)) {
    orig_col <- names(columns_map)[i]
    clean_name <- columns_map[i]

    # Ensure the target column is pulled safely
    files_all <- files_all_combined %>%
        dplyr::select(all_of(orig_col), wave) %>%
        dplyr::rename(value = all_of(orig_col)) %>%
        dplyr::mutate(
            wave = as.factor(wave),
            calibration = as.character(wave),
            name = clean_name
        ) %>%
        dplyr::mutate(calibration = factor(calibration, levels = unique(calibration), ordered = TRUE))

    plots[[i]] <- ggplot(data = files_all, aes(x = value, group = calibration, fill = calibration, colour = calibration)) +
        geom_density(aes(y = after_stat(scaled)), alpha = 0.5, linewidth = 0.8) +

        # Moves the titles to the bottom of the subplots
        facet_wrap(~name, scales = "free", ncol = 1, strip.position = "bottom") +
        scale_fill_manual(values = cbp1) +
        scale_colour_manual(values = cbp1) +

        # Completely strips background, axes, and borders
        theme_void() +
        theme(
            panel.background = element_rect(fill = "transparent", color = NA),
            plot.background = element_rect(fill = "transparent", color = NA),
            strip.background = element_blank(), # Removes the background box
            strip.text = element_text(color = "#005750", family = "Roboto Mono", face = "bold", size = 16, margin = margin(t = 10, b = 5)),
            plot.margin = margin(10, 10, 10, 10),
            legend.position = "none"
        )
}

# --- Custom 3-3-2 centered Layout ---
# design string represents the rows: Row 1 has A, B, C; Row 2 has D, E, F;
# Row 3 has a spacer, then G and H (offsetting them closer to the center).
design <- "
  AABBCC
  DDEEFF
  #GGHH#
"

# --- 4. Assemble and Save Multi-Panel Grid ---
big_plot <- wrap_plots(plots, design = design) &
    theme(
        plot.background = element_rect(
            fill = "transparent", color = NA
        )
    )

# Display the output directly in R
# print(big_plot)

# Save to file
ggsave("assets/img/calibration_waves_clean.png", big_plot,
    dpi = 300, width = 33, height = 16, units = "cm", device = ragg::agg_png
)
