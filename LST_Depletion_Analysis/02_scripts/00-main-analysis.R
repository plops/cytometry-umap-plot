# -----------------------------------------------------------------------------
# SETUP: Load Libraries and Define Paths
# -----------------------------------------------------------------------------

# Install Bioconductor packages if you haven't already
# if (!requireNamespace("BiocManager", quietly = TRUE))
#     install.packages("BiocManager")
# BiocManager::install(c("flowCore", "flowWorkspace", "ggcyto", "tidyverse"))

library(flowCore)
library(flowWorkspace)
library(ggcyto)
library(tidyverse)

# Define file paths
fcs_path <- "01_data/fcs/"
output_path <- "03_output/"

# Create output directories if they don't exist
dir.create(file.path(output_path, "plots"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_path, "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_path, "processed_data"), recursive = TRUE, showWarnings = FALSE)


# Load all FCS files from the directory into a flowSet
fcs_files <- list.files(fcs_path, pattern = ".fcs", full.names = TRUE)
if (length(fcs_files) == 0) {
  stop("No FCS files found in '01_data/fcs/'. Please add your data files.")
}
fs <- read.flowSet(fcs_files)

# -----------------------------------------------------------------------------
# STEP 0: Compensation
# -----------------------------------------------------------------------------
# Based on the spillover matrix from the .wsp file.
# Note: The matrix values are proportions (percentage / 100).

# Define the channel names that are part of the spillover matrix
spill_channels <- c("BV421-A", "BV510-A", "BV605-A", "BV650-A", "BV786-A",
                    "BB515-A", "PE-A", "PE-CF594-A", "PerCP-Cy5-5-A",
                    "APC-A", "APC-R700-A", "APC-Cy7-A")

# Create the spillover matrix from the provided values
spillover_matrix <- matrix(c(
  1.0000, 0.0693, 0.0199, 0.0000, 0.0287, 0.0000, 0.0001, 0.0003, 0.0000, 0.0000, 0.0000, 0.0002,
  0.1552, 1.0000, 0.0000, 0.0000, 0.0056, 0.1234, 0.0061, 0.0012, 0.0000, 0.0000, 0.0000, 0.0007,
  0.0071, 0.3164, 1.0000, 0.0000, 0.0009, 0.0143, 0.1415, 0.4062, 0.1953, 0.0000, 0.0000, 0.0000,
  0.0016, 0.1563, 0.6567, 1.0000, 0.0029, 0.0040, 0.0427, 0.2127, 1.0276, 0.0801, 0.0223, 0.0055,
  0.0001, 0.0170, 0.0633, 0.0000, 1.0000, 0.0000, 0.0028, 0.0162, 0.1665, 0.0060, 0.0292, 0.1238,
  0.0000, 0.0013, 0.0002, 0.0000, 0.0000, 1.0000, 0.0074, 0.0017, 0.0000, 0.0000, 0.0000, 0.0002,
  0.0000, 0.0010, 0.0062, 0.0000, 0.0000, 0.3270, 1.0000, 0.1586, 0.0280, 0.0000, 0.0000, 0.0001,
  0.0000, 0.0005, 0.0182, 0.0000, 0.0000, 0.0775, 0.2992, 1.0000, 0.2582, 0.0000, 0.0000, 0.0002,
  0.0000, 0.0004, 0.0070, 0.0000, 0.0000, 0.0143, 0.0654, 0.3457, 1.0000, 0.0020, 0.0085, 0.0000,
  0.0000, 0.0000, 0.0031, 0.0000, 0.0004, 0.0000, 0.0000, 0.0055, 0.1585, 1.0000, 0.3959, 0.0637,
  0.0000, 0.0000, 0.0001, 0.0000, 0.0031, 0.0000, 0.0001, 0.0008, 0.0459, 0.1487, 1.0000, 0.0694,
  0.0000, 0.0002, 0.0000, 0.0000, 0.0376, 0.0000, 0.0000, 0.0000, 0.0173, 0.0543, 0.2913, 1.0000
), nrow = 12, byrow = FALSE) # Data is column-major from the prompt table

# Assign channel names to the matrix
dimnames(spillover_matrix) <- list(spill_channels, spill_channels)

# Apply the compensation to the flowSet
# The FCS files are already compensated, but we apply it here to ensure
# the compensated parameters are available for gating.
# We will use the 'compensation' object for this.
comp <- compensation(spillover_matrix)
gs <- GatingSet(fs)
gs <- compensate(gs, comp)


# -----------------------------------------------------------------------------
# STEP 1: Gating Strategy
# -----------------------------------------------------------------------------

# Gate 1: Lymphocytes (Polygon Gate)
lymph_gate_vertices <- matrix(c(
  71593.9, 37622.5, 73796.8, 31554.4, 78202.6, 27913.5, 82608.4, 25486.2,
  90318.5, 25486.2, 94724.3, 29127.1, 99130.1, 31554.4, 104637.3, 36408.9,
  107941.6, 40049.8, 111246.0, 44904.3, 113448.9, 49758.8, 115651.8, 55827.0,
  115651.8, 63108.7, 111246.0, 69176.9, 107941.6, 71604.1, 101333.0, 75245.0,
  96927.2, 77672.3, 89217.1, 77672.3, 84811.3, 72817.8, 82608.4, 67963.3,
  80405.5, 61895.1, 79304.1, 55827.0, 75999.7, 49758.8, 72695.4, 43690.7
), ncol = 2, byrow = TRUE)
colnames(lymph_gate_vertices) <- c("FSC-A", "SSC-A")
lymph_gate <- polygonGate(.gate = lymph_gate_vertices, filterId = "Lymphocytes")
add(gs, lymph_gate, parent = "root")

# Gate 2a: Single Cells (from Lymphocytes)
single_cells_2a_vertices <- matrix(c(
  20927.5, 30340.7, 28637.6, 25486.2, 95825.7, 91022.2, 94724.3, 109226.7
), ncol = 2, byrow = TRUE)
colnames(single_cells_2a_vertices) <- c("SSC-A", "SSC-H")
single_cells_2a_gate <- polygonGate(.gate = single_cells_2a_vertices, filterId = "Single_Cells_a")
add(gs, single_cells_2a_gate, parent = "Lymphocytes")

# Gate 2b: Single Cells (from Gate 2a)
single_cells_2b_vertices <- matrix(c(
  63883.8, 69176.9, 72695.4, 66749.6, 123361.9, 117722.1, 122260.4, 134712.9
), ncol = 2, byrow = TRUE)
colnames(single_cells_2b_vertices) <- c("FSC-A", "FSC-H")
single_cells_2b_gate <- polygonGate(.gate = single_cells_2b_vertices, filterId = "Single_Cells")
add(gs, single_cells_2b_gate, parent = "Single_Cells_a")

# Gate 3: Live Cells (Rectangle Gate)
# Note: We use the compensated channel name here.
live_gate <- rectangleGate(
  "Comp-PerCP-Cy5-5-A" = c(-323.58, 543.07),
  "FSC-H" = c(16990.81, 241512.30),
  filterId = "Live_Cells"
)
add(gs, live_gate, parent = "Single_Cells")

# Gate 4: CD3+ T-Cells (Rectangle Gate)
cd3_gate <- rectangleGate(
  "Comp-APC-A" = c(1801.68, 132607.86),
  "FSC-H" = c(41263.41, 146849.19),
  filterId = "CD3+"
)
add(gs, cd3_gate, parent = "Live_Cells")

# Gate 5: CD4/CD8 Quadrant Gate
quad_gate <- quadGate(
  "Comp-PE-A" = 638.66,      # CD8
  "Comp-BV786-A" = 1846.06,   # CD4
  filterId = "CD4_CD8_Quad"
)
add(gs, quad_gate, parent = "CD3+")

# Recompute the gating tree to apply all gates
recompute(gs)

# -----------------------------------------------------------------------------
# STEP 2: Visualization and Analysis
# -----------------------------------------------------------------------------

# --- Plotting the Gating Strategy ---
# It's good practice to plot each step for one sample to verify gates
sample_to_plot <- sampleNames(gs)[1]

# Plot Lymphocyte Gate
p1 <- ggcyto(gs, aes(x = `FSC-A`, y = `SSC-A`), subset = "root") +
  geom_hex(bins = 128) +
  geom_gate("Lymphocytes") +
  ggcyto_par_set(limits = "data") +
  facet_wrap(~name)
ggsave(file.path(output_path, "plots", "01_Lymphocyte_Gate.png"), plot = p1, width = 10, height = 8)

# Plot Singlet Gating
p2a <- ggcyto(gs, aes(x = `SSC-A`, y = `SSC-H`), subset = "Lymphocytes") +
  geom_hex(bins = 128) + geom_gate("Single_Cells_a") + ggcyto_par_set(limits = "data") + facet_wrap(~name)
p2b <- ggcyto(gs, aes(x = `FSC-A`, y = `FSC-H`), subset = "Single_Cells_a") +
  geom_hex(bins = 128) + geom_gate("Single_Cells") + ggcyto_par_set(limits = "data") + facet_wrap(~name)
ggsave(file.path(output_path, "plots", "02a_Singlet_Gate_SSC.png"), plot = p2a, width = 10, height = 8)
ggsave(file.path(output_path, "plots", "02b_Singlet_Gate_FSC.png"), plot = p2b, width = 10, height = 8)

# Plot Live Cell Gate
p3 <- ggcyto(gs, aes(x = `Comp-PerCP-Cy5-5-A`, y = `FSC-H`), subset = "Single_Cells") +
  geom_hex(bins = 128) +
  geom_gate("Live_Cells") +
  ggcyto_par_set(limits = "data") +
  facet_wrap(~name)
ggsave(file.path(output_path, "plots", "03_Live_Cell_Gate.png"), plot = p3, width = 10, height = 8)

# Plot CD3 Gate
p4 <- ggcyto(gs, aes(x = `Comp-APC-A`, y = `FSC-H`), subset = "Live_Cells") +
  geom_hex(bins = 128) +
  geom_gate("CD3+") +
  ggcyto_par_set(limits = "data") +
  facet_wrap(~name)
ggsave(file.path(output_path, "plots", "04_CD3_Gate.png"), plot = p4, width = 10, height = 8)


# --- Generate Final Plots (like Figure 2B) ---
# Plot CD4 vs CD8 for all experimental samples
final_plot <- ggcyto(gs, aes(x = `Comp-PE-A`, y = `Comp-BV786-A`), subset = "CD3+") +
  geom_hex(bins = 256) +
  geom_gate() + # Automatically finds the CD4/CD8 quad gate
  geom_stats(type = c("percent"), digits = 2) + # Add quadrant percentages
  facet_wrap(~name) + # Create a separate plot for each FCS file
  labs(title = "CD4 vs. CD8 Expression in Live CD3+ T-Cells",
       x = "CD8 (Comp-PE-A)",
       y = "CD4 (Comp-BV786-A)") +
  theme_bw() +
  ggcyto_par_set(limits = "data")

ggsave(file.path(output_path, "plots", "Figure2B_Recreation.png"), plot = final_plot, width = 12, height = 10)


# --- Extracting Statistics ---
# Get the percentage of each population relative to its parent
stats_table <- gs_pop_get_stats(gs, type = "percent")
write.csv(stats_table, file.path(output_path, "tables", "gating_statistics.csv"), row.names = FALSE)

# You can also get stats for the final quadrants
quad_nodes <- gs_get_pop_paths(gs, path = "full")[grepl("CD4_CD8_Quad", gs_get_pop_paths(gs, path = "full"))]
quad_stats <- gs_pop_get_stats(gs, nodes = quad_nodes, type = "percent")
write.csv(quad_stats, file.path(output_path, "tables", "quadrant_statistics.csv"), row.names = FALSE)

# Save the GatingSet object for later use
saveRDS(gs, file = file.path(output_path, "processed_data", "gating_set.rds"))

print("Analysis complete. Check the '03_output' directory for results.")

# LST Depletion Check - Flow Cytometry Analysis

This project recreates the flow cytometry data processing pipeline described in the supplementary materials for [PMID: 37955593](https://pmc.ncbi.nlm.nih.gov/articles/PMC10622560/). The goal is to analyze the efficacy of CD4+ and CD8+ T-cell depletion in splenocytes.

The analysis is performed in R using packages from the Bioconductor project.

## Project Structure

```
/
|-- LST_Depletion_Analysis.Rproj  # RStudio Project File
|
|-- 01_data/
|   |-- fcs/                      # Directory for raw .fcs files
|       |-- .gitkeep              # Placeholder
|
|-- 02_scripts/
|   |-- 00-main-analysis.R        # Main R script for the entire pipeline
|
|-- 03_output/
|   |-- plots/                    # Directory for generated plots
|   |-- tables/                   # Directory for statistical tables (e.g., .csv)
|   |-- processed_data/           # Directory for processed R data objects (e.g., .rds)
|
|-- README.md                     # This file
```

## How to Run the Analysis

1.  **Prerequisites:**
    *   R and RStudio installed.
    *   All required `.fcs` files.

2.  **Setup:**
    *   Place all your raw `.fcs` files into the `01_data/fcs/` directory.
    *   Open the `LST_Depletion_Analysis.Rproj` file in RStudio. This will set the working directory correctly.

3.  **Install Packages:**
    *   Run the installation commands at the top of the `02_scripts/00-main-analysis.R` script to install the necessary Bioconductor packages (`flowCore`, `flowWorkspace`, `ggcyto`) and `tidyverse`.

4.  **Execute:**
    *   Open and run the `02_scripts/00-main-analysis.R` script from top to bottom.

5.  **Check Results:**
    *   The `03_output/` directory will be populated with:
        *   Plots (`.png`) visualizing the gating strategy and the final CD4/CD8 analysis.
        *   Tables (`.csv`) containing the population statistics for each gate and quadrant.


