This project visualizes high-dimensional cytometry data using UMAP
(Uniform Manifold Approximation and Projection), generating
interactive plots with Bokeh. The pipeline is optimized for
performance by leveraging NVIDIA's cuML for GPU-accelerated UMAP
computation and Joblib for caching intermediate results, which avoids
re-running computationally expensive steps.

![Screenshot of the interactive UMAP plot](https://raw.githubusercontent.com/plops/cytometry-umap-plot/main/img/plot.png)

### Features

*   High-dimensional data visualization using UMAP.
*   Interactive and explorable plots powered by Bokeh.
*   GPU acceleration for UMAP via NVIDIA cuML for significant speed-up.
*   Efficient caching of intermediate results with Joblib to avoid re-computation.
*   Configurable data processing and plotting parameters via a `config.yml` file.

### Technology Stack

*   Python
*   `uv` for dependency management
*   NVIDIA RAPIDS (`cuml-cu12`, `cudf-cu12`) for GPU acceleration
*   `umap-learn` for the UMAP algorithm
*   `Bokeh` for interactive plotting
*   `Pandas` for data manipulation
*   `Joblib` for caching
*   `readfcs` for reading Flow Cytometry Standard (`.fcs`) files

### Getting Started

#### Prerequisites

*   An NVIDIA GPU with CUDA 12.x installed.
*   Python 3.x.
*   `uv` package manager. This can be obtained using `pip install uv`, if you have pip.

#### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/plops/cytometry-umap-plot.git
    cd cytometry-umap-plot
    ```

2. Download a dataset and modify paths.fcs_data_datadir to point to
the directory containing the *.fcs files.

#### Dataset

The example data used in this project is from the FlowRepository,
specifically dataset `FR-FCM-Z6UG`. You can obtain the data from this
[FlowRepository](http://flowrepository.org/id/FR-FCM-Z6UG) page using
the link `Download FCS Files`.

Place your `.fcs` files in the data directory specified in
`config.yml` (e.g., `data/`).

### Configuration

Project settings, such as file paths, UMAP parameters, and plotting
options, are managed in the `config.yml` file. This allows for easy
experimentation without modifying the source code.

### Usage

To generate the UMAP visualization, run the main script:

```bash
cd cyto-plot
uv run main.py
```

On its first run the script will download the dependencies (7.2GB)
into the folder cyto-plot/.venv.

The script will process the `.fcs` files, perform UMAP dimensionality
reduction, and save an interactive HTML plot in the specified output
directory.

The first run with a new dataset or after you have modified the
`config.yml` file will be slower as it populates the cache. Subsequent
runs will be significantly faster, loading the pre-computed data and
UMAP embedding directly from the `cache/` directory. If you encounter
issues, clearing the cache/ directory will force a fresh computation.


## Interpretation of the example dataset:

The experiment in the publication "Determining the role of CD4+ and
CD8+ T-cells in the LST response" (PMCID: PMC10622560)
https://pmc.ncbi.nlm.nih.gov/articles/PMC10622560/ investigates the
cellular basis of the Leishmanin Skin Test (LST), a delayed-type
hypersensitivity response crucial for diagnosing and assessing
immunity to Leishmaniasis. The researchers used flow cytometry to
analyze splenocytes from mice to validate their LST antigen and to
determine the roles of different T-cell populations.

Looking at the diagram in Figure 2 of the paper, I don't think UMAP is
required for this data.


Here is a detailed explanation of what each FCS column represents in
the context of this study. An (estimated) cytometry data processing procedure is discussed in https://github.com/plops/cytometry-umap-plot/blob/main/doc/processing.md:

### **Light Scatter Columns: Defining Basic Cell Properties**

These columns are fundamental to flow cytometry and are used for the initial identification and quality control of the cell populations being analyzed.

*   **'FSC-A' (Forward Scatter - Area), 'FSC-H' (Forward Scatter - Height), and 'FSC-W' (Forward Scatter - Width):** Forward scatter is proportional to the size of a cell. In this experiment, these parameters would be used to focus the analysis on lymphocytes, which are typically smaller than other splenocytes like macrophages. The FSC-A versus FSC-H plot is also a primary tool to exclude "doublets" – two or more cells stuck together that would otherwise be incorrectly analyzed as a single, larger cell.

*   **'SSC-A' (Side Scatter - Area), 'SSC-H' (Side Scatter - Height), and 'SSC-W' (Side Scatter - Width):** Side scatter reflects the internal complexity or granularity of a cell. Lymphocytes have a low side scatter signal. This property is used to distinguish them from granulocytes (like neutrophils), which have a high side scatter signal due to their granular cytoplasm.

### **Fluorescence Channels and Cellular Markers: Identifying and Quantifying Immune Cells**

These columns represent the fluorescence emitted from specific dyes (fluorochromes) that are attached to antibodies. These antibodies, in turn, bind to specific proteins (markers) on the cell surface, allowing for the identification and counting of different cell types. The "-A" in names like 'BV421-A' signifies that the **Area** of the fluorescence signal was measured, which is the standard method for quantifying the total fluorescence of a cell as it passes the laser.

*   **'Live/Dead':** This channel is for a viability stain. This is a critical first step in the data analysis to exclude dead cells. Dead cells can non-specifically bind antibodies, which would lead to inaccurate results. For this experiment, only live cells are included in the subsequent analysis of T-cell populations.

*   **'CD45':** This is a pan-leukocyte marker, meaning it is found on all white blood cells. Staining for CD45 is used to create a "leukocyte gate," ensuring that the analysis is restricted to immune cells from the spleen and excludes other cell types or debris.

*   **'CD3':** This is a pan-T-cell marker. It is part of the T-cell receptor complex and is used to positively identify all T-cells within the CD45-positive leukocyte population. This is a crucial step before drilling down into the specific T-cell subsets.

*   **'CD4':** This marker identifies helper T-cells. A central goal of this study was to determine the role of these cells in the LST response. The experiment involved depleting CD4+ T-cells using an anti-CD4 monoclonal antibody (clone GK1.5). The 'CD4' column is therefore essential for quantifying the number of these cells and, as stated in the paper, to "confirm" the successful depletion of this cell population in the treated mice.

*   **'CD8':** This marker identifies cytotoxic T-cells. Similar to CD4+ cells, the study aimed to understand the contribution of CD8+ T-cells. This was achieved by depleting them with an anti-CD8 antibody (clone YTS169.4). The 'CD8' column is used to quantify these cells and verify the effectiveness of the depletion. The paper's conclusion that "both the CD4+ and CD8+ T-cells are necessary for the leishmanin skin test response" is directly supported by the data from these channels.

### **Fluorochrome Channels: The Specific Detectors**

These column names refer to the specific fluorescent dyes and the detectors (channels) in the flow cytometer that measure their light emission. Each of the cellular markers described above would have been linked to one of these fluorochromes.

*   **'BV421-A', 'BV510-A', 'BV605-A', 'BV650-A':** These are Brilliant Violet™ dyes, a family of polymer-based dyes known for their exceptional brightness. The number indicates the peak emission wavelength (e.g., 421 nm).

*   **'BB515-A':** This refers to a Brilliant Blue dye, another bright fluorochrome with an emission around 515 nm.

*   **'PE-CF594-A':** This is a tandem dye. Phycoerythrin (PE) is excited by the laser and transfers its energy to the CF594 dye, which then emits light at a longer wavelength (around 594 nm). Tandem dyes are used to increase the number of different markers that can be measured simultaneously in a single experiment.

*   **'APC-R700-A':** This is another tandem dye, where Allophycocyanin (APC) is conjugated to a dye that emits light at approximately 700 nm.