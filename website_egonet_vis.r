# ==============================================================================
# Modernized Ego-Network Visualization Generator for Websites
# Re-architected with ggraph, tidygraph, and ggplot2
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Environment Setup & Library Loading
# ------------------------------------------------------------------------------
library(data.table)
library(dplyr)
library(readr)
library(igraph)
library(tidygraph)
library(ggraph)
library(ggplot2)
library(patchwork)
library(svglite) # For exporting clean, scalable SVGs to your website

# --- Custom Styling Config (Dark Mode by default, perfect for modern web portfolios) ---
web_config <- list(
  bg_color = "#0d0d15", # Deep midnight dark background
  grid_bg_color = "#11111d", # Slightly lighter card background for network grids
  text_color = "#ffffff", # White text
  sub_text_color = "#a0a0b0", # Muted grey text
  edge_color = "rgba(255,255,255,0.15)", # Semi-transparent white paths
  # Sophisticated modern web-safe color palettes
  palettes = list(
    smokingstatus = c("1" = "#ff416c", "0" = "#00b0ff"), # Neon Red (Smoker) vs Neon Blue
    vapingstatus  = c("1" = "#ff9100", "0" = "#00e676"), # Orange (Vaper) vs Emerald
    sex           = c("1" = "#2979ff", "2" = "#ec407a"), # Classic Blue vs Pink
    eduCat        = c("1" = "#e040fb", "2" = "#ffd600", "3" = "#00e5ff"), # Low, Med, High
    ageCat        = c("#ff1744", "#ff5252", "#ff4081", "#e040fb", "#7c4dff", "#536dfe", "#00e5ff")
  )
)

# ------------------------------------------------------------------------------
# 2. Robust Data Loading & Fail-Safe Integration
# ------------------------------------------------------------------------------
# Define your directories
ResultsDir <- "/home/cmp24psl/CRUK/myvirtualenv/Results/2025-11-28_1/"
# results dir to save to cuurent working directory
FiguresResultsDir <- paste0(getwd(), "static/img/website_egonet_vis/")
if (!dir.exists(FiguresResultsDir)) {
  dir.create(FiguresResultsDir, recursive = TRUE)
}

# Load main edgelist
edgeList <- read_csv(paste0(ResultsDir, "outputs/edgeLists/wave_10/edgeList_247.csv"))

# Load population (with synthetic fallback if testing locally without complete files)
if (file.exists(paste0(ResultsDir, "smoking_agents.csv"))) {
  population <- fread(paste0(ResultsDir, "smoking_agents.csv"))
} else {
  warning("smoking_agents.csv not found! Constructing synthetic demographic variables for rendering...")
  # Create a synthetic fallback matching your script's schema so the pipeline doesn't crash
  unique_ids <- unique(c(edgeList$ego.id, edgeList$alter.id))
  population <- data.table(
    microsim.init.id = unique_ids,
    smokingstatus = sample(c(0, 1), length(unique_ids), replace = TRUE, prob = c(0.7, 0.3)),
    vapingstatus = sample(c(0, 1), length(unique_ids), replace = TRUE, prob = c(0.8, 0.2)),
    agecat = sample(1:7, length(unique_ids), replace = TRUE),
    microsim.init.sex = sample(c(1, 2), length(unique_ids), replace = TRUE),
    microsim.init.education = sample(c(1, 2, 3), length(unique_ids), replace = TRUE)
  )
}

# ------------------------------------------------------------------------------
# 3. Core Network Builder Function (With Safe Variable Initializations)
# ------------------------------------------------------------------------------
build_ego_data <- function(agent_id, step_number = 1) {
  # Safe initializations so R doesn't crash during lazy case_when evaluation
  alters_alters <- character(0)
  alters_alters_alters <- character(0)

  # Step 1: Direct ego edges
  ego_edges <- edgeList %>% filter(ego.id == agent_id | alter.id == agent_id)

  if (nrow(ego_edges) == 0) {
    # Isolated agent
    nodes_df <- population %>%
      filter(microsim.init.id == agent_id) %>%
      select(id = microsim.init.id, smokingstatus, vapingstatus, ageCat = agecat, sex = microsim.init.sex, eduCat = microsim.init.education) %>%
      mutate(
        id = as.character(id),
        node_type = "Ego",
        distance = 0
      )

    return(tbl_graph(nodes = nodes_df, edges = data.frame(from = character(0), to = character(0))))
  }

  # Step 2: Extract neighbors recursively based on steps
  direct_alters <- unique(c(ego_edges$ego.id, ego_edges$alter.id))
  direct_alters <- direct_alters[direct_alters != agent_id]

  all_agents <- c(agent_id, direct_alters)

  if (step_number >= 2) {
    alter_edges <- edgeList %>% filter(ego.id %in% direct_alters | alter.id %in% direct_alters)
    alters_alters <- unique(c(alter_edges$ego.id, alter_edges$alter.id))
    alters_alters <- alters_alters[!alters_alters %in% all_agents]
    all_agents <- c(all_agents, alters_alters)
  }

  if (step_number >= 3) {
    alter_alter_edges <- edgeList %>% filter(ego.id %in% alters_alters | alter.id %in% alters_alters)
    alters_alters_alters <- unique(c(alter_alter_edges$ego.id, alter_alter_edges$alter.id))
    alters_alters_alters <- alters_alters_alters[!alters_alters_alters %in% all_agents]
    all_agents <- c(all_agents, alters_alters_alters)
  }

  # Slice attributes from population and cast ID to character
  nodes_df <- population %>%
    filter(microsim.init.id %in% all_agents) %>%
    select(id = microsim.init.id, smokingstatus, vapingstatus, ageCat = agecat, sex = microsim.init.sex, eduCat = microsim.init.education) %>%
    mutate(
      id = as.character(id),
      node_type = case_when(
        id == as.character(agent_id) ~ "Ego",
        id %in% as.character(direct_alters) ~ "Direct Alter",
        (step_number >= 2) & (!id %in% as.character(c(agent_id, direct_alters))) & (!id %in% as.character(alters_alters_alters)) ~ "2-Step Alter",
        (step_number >= 3) & (id %in% as.character(alters_alters_alters)) ~ "3-Step Alter",
        TRUE ~ "2-Step Alter"
      ),
      distance = case_when(
        id == as.character(agent_id) ~ 0,
        id %in% as.character(direct_alters) ~ 1,
        (step_number >= 2) & (!id %in% as.character(c(agent_id, direct_alters))) & (!id %in% as.character(alters_alters_alters)) ~ 2,
        (step_number >= 3) & (id %in% as.character(alters_alters_alters)) ~ 3,
        TRUE ~ 2
      )
    )

  # Fetch all connected ties among these nodes, converting to character
  edges_df <- edgeList %>%
    filter(ego.id %in% all_agents & alter.id %in% all_agents) %>%
    select(from = ego.id, to = alter.id) %>%
    mutate(
      from = as.character(from),
      to = as.character(to)
    ) %>%
    distinct()

  # Create tidygraph and safely join on character keys
  g <- as_tbl_graph(edges_df, directed = TRUE) %>%
    activate(nodes) %>%
    left_join(nodes_df, by = c("name" = "id"))

  return(g)
}

# ------------------------------------------------------------------------------
# 4. Stylized Web-Rendering Plot Engine (Individual Plots)
# ------------------------------------------------------------------------------
plot_single_web_ego <- function(agent_id, step_number = 1, color_by = "smokingstatus") {
  # Build graph
  g <- build_ego_data(agent_id, step_number)

  # Map modern coloring attribute
  g <- g %>%
    activate(nodes) %>%
    mutate(color_var = as.factor(.data[[color_by]]))

  # Configure node sizes based on distances
  sizes <- c("Ego" = 6, "Direct Alter" = 3.5, "2-Step Alter" = 2.0, "3-Step Alter" = 1.2)

  # Create a clean label name for the legend title (e.g., "Smoking Status")
  legend_title <- switch(color_by,
    "smokingstatus" = "Smoking Status",
    "vapingstatus"  = "Vaping Status",
    "sex"           = "Sex",
    "eduCat"        = "Education Level",
    "ageCat"        = "Age Category",
    color_by
  )

  p <- ggraph(g, layout = "stress") +
    geom_edge_arc(aes(start_cap = label_rect(node1.node_type), end_cap = label_rect(node2.node_type)),
      color = "grey60", alpha = 0.25, strength = 0.2, width = 0.35,
      arrow = arrow(angle = 18, length = unit(2.0, "mm"), type = "closed")
    ) +
    geom_node_point(aes(color = color_var, size = node_type), alpha = 0.95) +
    scale_size_manual(values = sizes, guide = "none") +
    scale_color_manual(
      values = web_config$palettes[[color_by]],
      name = legend_title,
      labels = if (color_by == "smokingstatus") {
        c("Non-Smoker", "Smoker")
      } else if (color_by == "vapingstatus") {
        c("Non-Vaper", "Vaper")
      } else {
        waiver()
      }
    ) +
    # Highlight the main Ego node with a soft glowing white outer ring
    geom_node_point(aes(filter = (node_type == "Ego")), shape = 1, size = 8, stroke = 1.0, color = "#ffffff", alpha = 0.8) +
    theme_void() +
    theme(
      plot.background = element_rect(fill = "transparent", color = NA),
      panel.background = element_rect(fill = "transparent", color = NA),
      # Keep the legend active here so patchwork can collect it
      legend.position = "right",
      plot.margin = margin(t = 12, r = 12, b = 12, l = 12, unit = "pt")
    )

  return(p)
}

# ------------------------------------------------------------------------------
# 5. Grid Generator Engine (With Single Unified Legend & Gaps)
# ------------------------------------------------------------------------------
plot_web_ego_grid <- function(grid_size = 5, smoking_status = 1, step_number = 1, color_by = "smokingstatus") {
  n_plots <- grid_size^2

  # Sample agents matching criteria
  sampled_agents <- population %>%
    filter(smokingstatus == smoking_status) %>%
    sample_n(n_plots) %>%
    pull(microsim.init.id)

  # Generate isolated plot objects
  plot_list <- lapply(sampled_agents, function(id) {
    plot_single_web_ego(id, step_number = step_number, color_by = color_by)
  })

  # Stitch together with patchwork, collecting all duplicate legends into one
  grid_plot <- wrap_plots(plot_list, ncol = grid_size) +
    plot_layout(guides = "collect") + # Collects the duplicate legends into one!
    plot_annotation(
      theme = theme(
        plot.background = element_rect(fill = "transparent", color = NA),
        panel.background = element_rect(fill = "transparent", color = NA),
        plot.margin = margin(t = 24, r = 24, b = 40, l = 24, unit = "pt"),

        # Style the single collected legend to look clean on web overlays
        legend.position = "bottom",
        legend.box = "horizontal",
        legend.background = element_rect(fill = "#fafdfe", color = NA),
        legend.key = element_rect(fill = "#fafdfe", color = NA),
        legend.title = element_text(color = "#fafdfe", face = "bold", size = 14),
        legend.text = element_text(color = "#fafdfe", size = 14)
      )
    )

  return(grid_plot)
}

# ==============================================================================
# 6. Run & Export Web Assets (Batch Generation - 1-Step & 2-Step)
# ==============================================================================

# Define a batch generation matrix to loop over
export_scenarios <- list(
  # ------------------ SMOKING STATUS GRIDS ------------------
  list(
    name = "smokers_1step",
    smoking_status = 1, # Filter egos who are Smokers
    step_number = 1, # Direct alters only
    color_by = "smokingstatus",
    grid_size = 5,
    msg = "Generating: 5x5 Smoker Ego Networks (1-Step, Colored by Smoking)"
  ),
  list(
    name = "smokers_2step",
    smoking_status = 1, # Filter egos who are Smokers
    step_number = 2, # Includes alter's alters (2nd Level)
    color_by = "smokingstatus",
    grid_size = 3, # 3x3 is cleaner for dense 2-step networks
    msg = "Generating: 3x3 Smoker Ego Networks (2-Step, Colored by Smoking)"
  ),
  list(
    name = "nonsmokers_1step",
    smoking_status = 0, # Filter egos who are Non-Smokers
    step_number = 1,
    color_by = "smokingstatus",
    grid_size = 5,
    msg = "Generating: 5x5 Non-Smoker Ego Networks (1-Step, Colored by Smoking)"
  ),
  list(
    name = "nonsmokers_2step",
    smoking_status = 0, # Filter egos who are Non-Smokers
    step_number = 2,
    color_by = "smokingstatus",
    grid_size = 3,
    msg = "Generating: 3x3 Non-Smoker Ego Networks (2-Step, Colored by Smoking)"
  ),

  # ------------------ VAPING STATUS GRIDS ------------------
  list(
    name = "vapers_1step",
    smoking_status = 1, # Can target smokers who vape, or customize if your population allows vaping filters
    step_number = 1,
    color_by = "vapingstatus",
    grid_size = 5,
    msg = "Generating: 5x5 Ego Networks (1-Step, Colored by Vaping)"
  ),
  list(
    name = "vapers_2step",
    smoking_status = 1,
    step_number = 2, # Includes alter's alters (2nd Level)
    color_by = "vapingstatus",
    grid_size = 3,
    msg = "Generating: 3x3 Ego Networks (2-Step, Colored by Vaping)"
  )
)

# Loop through and render each asset automatically
for (scenario in export_scenarios) {
  message(scenario$msg)

  # Generate the grid plot dynamically using our transparent engine
  p_grid <- plot_web_ego_grid(
    grid_size = scenario$grid_size,
    smoking_status = scenario$smoking_status,
    step_number = scenario$step_number,
    color_by = scenario$color_by
  )

  # 1. Export as a crisp vector SVG for high-end scaling
  ggsave(
    filename = paste0(FiguresResultsDir, "web_ego_", scenario$name, ".svg"),
    plot = p_grid,
    width = 16, height = 9,
    bg = "transparent"
  )

  # 2. Export as PNG matching your 2560x1440 sphere asset pixel-for-pixel
  ggsave(
    filename = paste0(FiguresResultsDir, "web_ego_", scenario$name, ".png"),
    plot = p_grid,
    width = 16, height = 9,
    dpi = 160,
    bg = "transparent"
  )
}

message("Success! All batch-generated transparent assets (1-step & 2-step) are exported to your directory!")
