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
