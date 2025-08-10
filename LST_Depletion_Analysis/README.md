# LST Depletion Check - Flow Cytometry Analysis

This project recreates a flow cytometry data processing pipeline to analyze the efficacy of CD4+ and CD8+ T-cell depletion in splenocytes. The analysis is performed in R using packages from the Bioconductor project, emphasizing reproducibility and clarity.

## Project Structure

```
/LST_Depletion_Analysis/
|
|-- LST_Depletion_Analysis.Rproj
|
|-- 01_data/
|   |-- fcs/
|   |   |-- Spleenocytes_Tcells_Unstained_control_001.fcs
|   |   |-- Spleenocytes_Tcells_FMO- no CD4 staining_002.fcs
|   |   |-- Spleenocytes_Tcells_Vaccinated_aCD8_003.fcs
|   |   |-- Spleenocytes_Tcells_Vaccinated_Saline_004.fcs
|   |   |-- Spleenocytes_Tcells_Rag2KO_005.fcs
|   |   |-- ... (and all other .fcs files)
|
|-- 02_scripts/
|   |-- 00-main-analysis.R
|   |-- 01-functions.R
|
|-- 03_output/
|   |-- plots/
|   |-- tables/
|   |-- processed_data/
|
|-- README.md
```

*   **`01_data/fcs/`**: Place all your raw `.fcs` files here.
*   **`02_scripts/`**: This contains the R code. `00-main-analysis.R` is the primary script that runs the pipeline. `01-functions.R` can store any custom helper functions.
*   **`03_output/`**: Generated files are stored here. This includes plots (`.png`, `.pdf`), statistical summaries (`.csv`), and processed R data objects (`.rds`).
*   **`README.md`**: This file, explaining the project's purpose, how to run the analysis, and the contents of each directory.

## How to Run the Project

1.  **Set up:** Place your `.fcs` files in the `01_data/fcs` directory.
2.  **Open Project:** Double-click the `LST_Depletion_Analysis.Rproj` file to open RStudio.
3.  **Install Packages:** Run the installation commands at the top of `02_scripts/00-main-analysis.R` if you don't have the required packages (`flowCore`, `flowWorkspace`, `ggcyto`, `tidyverse`).
4.  **Execute Script:** Open `02_scripts/00-main-analysis.R` and run the entire script.
5.  **Check Output:** The `03_output` folder will be populated with plots recreating the analysis and CSV files containing the population statistics.

## Installation in Gentoo

```
sudo emerge -av R tk

```


## Discussion of Improvements and Further Questions

### Validating the Spillover Matrix
You can and should use your experimental controls to validate the compensation.
*   The **CD4-depleted sample** (`..._GK15_006.fcs`) should have only CD8+ T-cells. When you plot these cells (CD4 vs. CD8), they should form a tight population along the CD8 axis with no upward "slant" into the CD4 channel. Any slant indicates incorrect compensation from the PE (CD8) channel into the BV786 (CD4) channel.
*   The **CD8-depleted sample** (`..._aCD8_003.fcs`) allows for the reverse check. The remaining CD4+ T-cells should not slant into the CD8 channel.
