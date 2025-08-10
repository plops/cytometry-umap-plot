# -----------------------------------------------------------------------------
# SETUP: Load Libraries and Define Paths
# -----------------------------------------------------------------------------

# Install Bioconductor packages if you haven't already
# if (!requireNamespace("BiocManager", quietly = TRUE))
#     install.packages("BiocManager")
# BiocManager::install(c("flowCore", "flowWorkspace", "ggcyto"))
# install.packages('tidyverse')
library(flowCore)
library(flowWorkspace)
library(ggcyto)
library(tidyverse)

# Define file paths
fcs_path <- "../01_data/fcs/"
output_path <- "../03_output/"

print("--- SCRIPT START ---")
print(paste("FCS file path:", fcs_path))
print(paste("Output path:", output_path))

# Create output directories if they don't exist
dir.create(file.path(output_path, "plots"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_path, "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_path, "processed_data"), recursive = TRUE, showWarnings = FALSE)
print("Output directories created/ensured.")


# Load all FCS files from the directory into a flowSet
fcs_files <- list.files(fcs_path, pattern = ".fcs", full.names = TRUE)
if (length(fcs_files) == 0) {
  stop("No FCS files found in '01_data/fcs/'. Please add your data files.")
}
print(paste("Found", length(fcs_files), "FCS files to load:"))
print(fcs_files)
fs <- read.flowSet(fcs_files)
print("FCS files loaded into a flowSet.")
print("FlowSet summary:")
print(fs)
print(paste("Number of cells per file:"))
print(fsApply(fs, nrow))


# -----------------------------------------------------------------------------
# STEP 0: Compensation
# -----------------------------------------------------------------------------
# Based on the spillover matrix from the .wsp file
print("--- STEP 0: Compensation ---")

# Define the channel names that are part of the spillover matrix
spill_channels <- c("BV421-A", "BV510-A", "BV605-A", "BV650-A", "BV786-A",
                    "BB515-A", "PE-A", "PE-CF594-A", "PerCP-Cy5-5-A",
                    "APC-A", "APC-R700-A", "APC-Cy7-A")
print("Defined spillover channels.")

# Create the spillover matrix from the provided values
spillover_matrix <- matrix(c(
  1.0000, 0.1552, 0.0071, 0.0016, 0.0001, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000,
  0.0693, 1.0000, 0.3164, 0.1563, 0.0170, 0.0013, 0.0010, 0.0005, 0.0004, 0.0000, 0.0000, 0.0002,
  0.0199, 0.0000, 1.0000, 0.6567, 0.0633, 0.0002, 0.0062, 0.0182, 0.0070, 0.0031, 0.0001, 0.0000,
  0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000,
  0.0287, 0.0056, 0.0009, 0.0029, 1.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0004, 0.0031, 0.0376,
  0.0000, 0.1234, 0.0143, 0.0040, 0.0000, 1.0000, 0.3270, 0.0775, 0.0143, 0.0000, 0.0000, 0.0000,
  0.0001, 0.0061, 0.1415, 0.0427, 0.0028, 0.0074, 1.0000, 0.2992, 0.0654, 0.0000, 0.0001, 0.0000,
  0.0003, 0.0012, 0.4062, 0.2127, 0.0162, 0.0017, 0.1586, 1.0000, 0.3457, 0.0055, 0.0008, 0.0000,
  0.0000, 0.0000, 0.1953, 1.0276, 0.1665, 0.0000, 0.0280, 0.2582, 1.0000, 0.1585, 0.0459, 0.0173,
  0.0000, 0.0000, 0.0000, 0.0801, 0.0060, 0.0000, 0.0000, 0.0000, 0.0020, 1.0000, 0.1487, 0.0543,
  0.0000, 0.0000, 0.0000, 0.0223, 0.0292, 0.0000, 0.0000, 0.0000, 0.0085, 0.3959, 1.0000, 0.2913,
  0.0002, 0.0007, 0.0000, 0.0005, 0.1238, 0.0002, 0.0001, 0.0002, 0.0000, 0.0637, 0.0694, 1.0000
), nrow = 12, byrow = TRUE)

# Assign channel names to the matrix
dimnames(spillover_matrix) <- list(spill_channels, spill_channels)
print("Spillover matrix created:")
print(spillover_matrix)

# Apply the compensation to the flowSet
print("Applying compensation to the flowSet...")
fs_comp <- compensate(fs, spillover_matrix)
print("Compensation applied.")
print("Compensated flowSet summary:")
print(fs_comp)

# Create a GatingSet from the compensated data
print("Creating GatingSet from compensated data...")
gs <- GatingSet(fs_comp)
print("GatingSet created.")
print("GatingSet summary:")
print(gs)

# -----------------------------------------------------------------------------
# STEP 1: Gating Strategy
# Note: The channel names used for gating must now match the compensated parameters
# e.g., 'FSC-A' vs 'BV421-A'
# -----------------------------------------------------------------------------
print("--- STEP 1: Gating Strategy ---")

# Gate 1: Lymphocytes (Polygon Gate)
print("Adding Gate 1: Lymphocytes...")
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
gs_pop_add(gs, lymph_gate, parent = "root", name = "Lymphocytes")
print("Lymphocytes gate added.")

# Gate 2a: Single Cells (from Lymphocytes)
print("Adding Gate 2a: Single Cells (SSC-A vs SSC-H)...")
single_cells_2a_vertices <- matrix(c(
  20927.5, 30340.7, 28637.6, 25486.2, 95825.7, 91022.2, 94724.3, 109226.7
), ncol = 2, byrow = TRUE)
colnames(single_cells_2a_vertices) <- c("SSC-A", "SSC-H")
single_cells_2a_gate <- polygonGate(.gate = single_cells_2a_vertices, filterId = "Single_Cells_a")
gs_pop_add(gs, single_cells_2a_gate, parent = "Lymphocytes", name = "Single_Cells_a")
print("Single Cells gate 'a' added.")

# Gate 2b: Single Cells (from Gate 2a)
print("Adding Gate 2b: Single Cells (FSC-A vs FSC-H)...")
single_cells_2b_vertices <- matrix(c(
  63883.8, 69176.9, 72695.4, 66749.6, 123361.9, 117722.1, 122260.4, 134712.9
), ncol = 2, byrow = TRUE)
colnames(single_cells_2b_vertices) <- c("FSC-A", "FSC-H")
single_cells_2b_gate <- polygonGate(.gate = single_cells_2b_vertices, filterId = "Single_Cells")
gs_pop_add(gs, single_cells_2b_gate, parent = "Single_Cells_a", name = "Single_Cells")
print("Single Cells gate 'b' added.")

# Gate 3: Live Cells (Rectangle Gate)
print("Adding Gate 3: Live Cells...")
live_gate <- rectangleGate(
  "PerCP-Cy5-5-A" = c(-323.58, 543.07),
  "FSC-H" = c(16990.81, 241512.30),
  filterId = "Live_Cells"
)
gs_pop_add(gs, live_gate, parent = "Single_Cells", name = "Live_Cells")
print("Live Cells gate added.")

# Gate 4: CD3+ T-Cells (Rectangle Gate)
print("Adding Gate 4: CD3+ T-Cells...")
cd3_gate <- rectangleGate(
  "APC-A" = c(1801.68, 132607.86),
  "FSC-H" = c(41263.41, 146849.19),
  filterId = "CD3+"
)
gs_pop_add(gs, cd3_gate, parent = "Live_Cells", name = "CD3+")
print("CD3+ T-Cells gate added.")

# Gate 5: CD4/CD8 Quadrant Gate
print("Adding Gate 5: CD4/CD8 Quadrant Gate...")
# Quadrant gates are defined by the intersection point.
# We will add a quadGate, which automatically creates the four populations.
quad_gate <- quadGate(
  "PE-A" = 638.66,      # CD8
  "BV786-A" = 1846.06,   # CD4
  filterId = "CD4_CD8_Quad"
)
# Define the names for the four quadrants. Note the order is important:
# top-left, bottom-left, bottom-right, top-right
# CD4+CD8-, CD4-CD8-, CD4-CD8+, CD4+CD8+
quad_pop_names <- c("CD4+CD8-", "CD4-CD8-", "CD4-CD8+", "CD4+CD8+")
gs_pop_add(gs, quad_gate, parent = "CD3+", names = quad_pop_names)
print("CD4/CD8 Quadrant gate added.")

# Recompute the gating tree to apply all gates
print("Recomputing GatingSet to apply all gates...")
recompute(gs)
print("GatingSet recomputed.")
print("Current gating hierarchy:")
plot(gs) # This will print the tree to the console/plot pane

# -----------------------------------------------------------------------------
# STEP 2: Visualization and Analysis
# -----------------------------------------------------------------------------
print("--- STEP 2: Visualization and Analysis ---")

# --- Plotting the Gating Strategy ---
# It's good practice to plot each step for one sample to verify gates
sample_to_plot <- "Spleenocytes_Tcells_Vaccinated_Saline_004.fcs"
print(paste("Generating verification plots for sample:", sample_to_plot))

# Plot Lymphocyte Gate
print("Plotting Lymphocyte Gate...")
p1 <- ggcyto(gs[[sample_to_plot]], aes(x = "FSC-A", y = "SSC-A"), subset = "root") +
  geom_hex(bins = 128) +
  geom_gate("Lymphocytes")
ggsave(file.path(output_path, "plots", "01_Lymphocyte_Gate.png"), plot = p1)
print("Saved 01_Lymphocyte_Gate.png")

# Plot Singlet Gating
print("Plotting Singlet Gate...")
p2 <- ggcyto(gs[[sample_to_plot]], aes(x = "FSC-A", y = "FSC-H"), subset = "Single_Cells_a") +
  geom_hex(bins = 128) +
  geom_gate("Single_Cells")
ggsave(file.path(output_path, "plots", "02_Singlet_Gate.png"), plot = p2)
print("Saved 02_Singlet_Gate.png")

# Plot Live Cell Gate
print("Plotting Live Cell Gate...")
p3 <- ggcyto(gs[[sample_to_plot]], aes(x = "PerCP-Cy5-5-A", y = "FSC-H"), subset = "Single_Cells") +
  geom_hex(bins = 128) +
  geom_gate("Live_Cells")
ggsave(file.path(output_path, "plots", "03_Live_Cell_Gate.png"), plot = p3)
print("Saved 03_Live_Cell_Gate.png")


# --- Generate Final Plots (like Figure 2B) ---
print("Generating final CD4 vs CD8 plots for all samples...")
# Plot CD4 vs CD8 for all experimental samples
final_plot <- ggcyto(gs, aes(x = "PE-A", y = "BV786-A"), subset = "CD3+") +
  geom_hex(bins = 128) +
  geom_gate() + # Automatically finds the CD4/CD8 quad gate
  geom_stats(type = "percent") + # Add quadrant percentages
  facet_wrap(~name) + # Create a separate plot for each FCS file
  labs(title = "CD4 vs. CD8 Expression in Live CD3+ T-Cells",
       x = "CD8 (PE-A)",
       y = "CD4 (BV786-A)") +
  theme_bw()

ggsave(file.path(output_path, "plots", "Figure2B_Recreation.png"), plot = final_plot, width = 12, height = 10)
print("Saved Figure2B_Recreation.png")


# --- Extracting Statistics ---
print("--- Extracting Statistics ---")
# Get the percentage of each population relative to its parent
print("Extracting population statistics (percentages)...")
stats_table <- gs_pop_get_stats(gs, type = "percent")
write.csv(stats_table, file.path(output_path, "tables", "gating_statistics.csv"))
print("Saved gating_statistics.csv")

# You can also get stats for the final quadrants
print("Extracting quadrant statistics...")
quad_stats <- gs_pop_get_stats(gs, nodes=c("CD4+CD8-", "CD4+CD8+", "CD4-CD8+", "CD4-CD8-"), type="percent")
write.csv(quad_stats, file.path(output_path, "tables", "quadrant_statistics.csv"))
print("Saved quadrant_statistics.csv")

# Save the GatingSet object for later use
print("Saving GatingSet object...")
saveRDS(gs, file = file.path(output_path, "processed_data", "gating_set.rds"))
print("Saved gating_set.rds")

print("--- SCRIPT END ---")
print("Analysis complete. Check the '03_output' directory for results.")

