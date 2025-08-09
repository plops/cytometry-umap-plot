# Cytometry UMAP Analysis Project

This project loads cytometry `.fcs` files, performs GPU-accelerated UMAP analysis using RAPIDS cuML, and generates an interactive HTML plot.


## How to clean the cache

Intermediate files are stored in the `cache/joblib` directory. You can clear this cache to force a full re-computation:

```
rm -r cache/joblib
```

## How to run in an editor

Download [PyCharm](https://www.jetbrains.com/de-de/pycharm/). Open the project directory in PyCharm.
Configure the Python interpreter to use the virtual environment (select 'uv'). 

Open the `main.py` file and run it using the green play button in the top right corner of PyCharm.


## How to format and check the code

```
uv run ruff format
uv run ruff check
uv run ruff check --fix
```