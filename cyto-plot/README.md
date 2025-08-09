# Cytometry UMAP Analysis Project

This project loads cytometry `.fcs` files, performs GPU-accelerated UMAP analysis using RAPIDS cuML, and generates an interactive HTML plot.

## Setup

1.  **Install `uv`**:
    ```bash
    pip install uv
    ```

2.  **Create Environment and Install Dependencies**:
    `uv` will create a virtual environment and install all dependencies listed in `pyproject.toml`.
    ```bash
    uv sync
    ```
    *Note: This project requires an NVIDIA GPU and a compatible CUDA toolkit version for `cuml`.*

3.  **Add Data**:
    Place your `.fcs` files into the `data/` directory.

## Configuration

All settings are managed in `config.yml`. You can adjust paths, UMAP parameters, and other settings in this file without modifying the source code.

## How to Run

Execute the main pipeline script from the project root directory:

```bash
uv run main.py
```


The first run will be slower as it populates the cache. Subsequent runs will be significantly faster, loading the pre-computed data and UMAP embedding directly from the `cache/` directory.
The final `interactive_umap_plot.html` will be saved in your `output/` directory.


## How to run in an editor

Download [PyCharm](https://www.jetbrains.com/de-de/pycharm/). Open the project directory in PyCharm.
Configure the Python interpreter to use the virtual environment (select 'uv'). 

Open the `main.py` file and run it using the green play button in the top right corner of PyCharm.