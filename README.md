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

The dataset contains the following columns: 'FSC-A', 'FSC-H', 'FSC-W',
'SSC-A', 'SSC-H', 'SSC-W', 'BV421-A', 'BV510-A', 'BV605-A', 'BV650-A',
'CD4', 'BB515-A', 'CD8', 'PE-CF594-A', 'Live/Dead', 'CD3',
'APC-R700-A', 'CD45'.

Note: This section was written by Google Gemini 2.5 Pro. I have no
idea about cytometry experiments.

The dataset is part of a study aimed at understanding the roles of
CD4+ and CD8+ T-cells in the immune response to a *Leishmania
donovani* antigen, using a mouse model.

Here is a breakdown of what the FCS columns mean in the context of
this specific experiment:

### Core Cell Properties (Scatter Channels)

These columns measure the intrinsic physical characteristics of the
splenocytes (cells from the spleen).

*   **'FSC-A', 'FSC-H', 'FSC-W' (Forward Scatter):** These parameters are used to determine the size of the cells being analyzed. This helps in the initial step of distinguishing lymphocytes (which are the primary focus here, including T-cells) from larger cells like macrophages or smaller debris. The width parameter is crucial for excluding clumps of cells (doublets) to ensure that each event analyzed corresponds to a single cell.
*   **'SSC-A', 'SSC-H', 'SSC-W' (Side Scatter):** These columns measure the internal complexity or granularity of the cells. Lymphocytes typically have low side scatter, while other immune cells like granulocytes (e.g., neutrophils) have high side scatter. This is another key parameter for isolating the lymphocyte population from the total splenocytes.

### Fluorescence and Specific Cell Markers

These columns measure the light emitted from fluorescent dyes that
have been used to label specific proteins (markers) on or in the
cells. The goal is to identify and quantify different T-cell
populations.

*   **'Live/Dead':** This channel is used to distinguish viable cells from dead cells. A fluorescent dye that can only enter cells with compromised membranes is used. This is a critical quality control step, as dead cells can non-specifically bind antibodies, leading to false-positive signals. For accurate analysis, dead cells are excluded.
*   **'CD45':** This is a pan-leukocyte marker, meaning it is present on nearly all white blood cells (leukocytes). In this experiment, it's used to positively identify all immune cells within the spleen sample and distinguish them from any non-hematopoietic cells or debris.
*   **'CD3':** This marker is a defining protein of the T-cell lineage. Staining for CD3 allows the researchers to specifically identify all T-cells within the broader population of CD45+ leukocytes.
*   **'CD4':** This marker identifies a major subset of T-cells known as helper T-cells. The experiment uses an antibody labeled with a fluorochrome to detect CD4. Based on the experimental conditions (e.g., "Spleenocytes_Tcells_Vaccinated_GK15"), the GK1.5 antibody was used, which is known to deplete CD4+ T-cells. This column is therefore essential for confirming the success of this depletion. The "FMO - no CD4 staining" control is used to set the gate for what is considered a positive signal for CD4.
*   **'CD8':** This marker identifies another major T-cell subset, the cytotoxic T-cells. The experiment includes a condition ("Spleenocytes_Tcells_Vaccinated_aCD8") where these cells are depleted. This column is used to quantify the CD8+ T-cell population and verify the depletion.

### Unassigned Fluorescence Channels

These are the detector channels that are capturing the fluorescence
signals from the antibody-dye conjugates. While the experiment
description doesn't explicitly link each dye to each marker, we can
infer the likely pairings.

*   **'BV421-A', 'BV510-A', 'BV605-A', 'BV650-A', 'BB515-A', 'PE-CF594-A', 'APC-R700-A':** These are the specific fluorescence detectors used. Each of the markers (CD45, CD3, CD4, CD8) and the Live/Dead stain would have been labeled with a dye corresponding to one of these channels. For example, the anti-CD3 antibody might be conjugated to PE-CF594, the anti-CD4 antibody to BV605, and so on. The exact combination would be detailed in the methods section of the associated manuscript. The "-A" signifies that the area of the signal pulse was measured, which is the standard and most robust way to quantify fluorescence intensity.

### Experimental Controls and Conditions

The file names and conditions listed provide further insight:

*   **Unstained Control:** Used to measure the baseline autofluorescence of the cells. This helps to determine the background signal in each channel.
*   **FMO (Fluorescence Minus One) Control:** This is a crucial control for setting accurate gates, especially for the CD4 marker as mentioned. It involves staining the cells with all the fluorescent antibodies *except* one (in this case, the anti-CD4 antibody). This reveals the spread of fluorescence from the other dyes into the channel of the omitted one, allowing for a more precise distinction between positive and negative populations.
*   **Rag2 KO Control:** Rag2 knockout mice lack functional T-cells and B-cells. These mice serve as a perfect negative control, confirming that the signals being detected for CD3, CD4, and CD8 are indeed from these cell types, as they should be absent in these mice.
*   **Undepleted (Saline):** This group represents the normal immune response in vaccinated mice without any cell depletion, serving as the positive control or baseline for the T-cell response.
*   **Depleted Samples (GK1.5 for CD4, aCD8 for CD8):** These are the core experimental groups. The data in these FCS files is used to confirm that the respective T-cell populations were successfully removed and to study the impact of their absence on the overall immune response.

## Related Paper

Nat Commun. 2023 Nov 2;14:7028. doi: 10.1038/s41467-023-42732-2
Production of leishmanin skin test antigen from Leishmania donovani for future reintroduction in the field

https://pmc.ncbi.nlm.nih.gov/articles/PMC10622560/
