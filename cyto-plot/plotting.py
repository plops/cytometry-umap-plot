import pandas as pd
import numpy as np
from bokeh.plotting import figure, save, output_file
from bokeh.models import HoverTool, ColumnDataSource
from pathlib import Path
from logger import logger


def generate_interactive_plot(
    embedding: np.ndarray, source_df: pd.DataFrame, output_path: Path
):
    """
    Generates an interactive Bokeh plot from the UMAP embedding and saves it to HTML.
    """
    logger.info(f"Generating interactive plot and saving to {output_path}...")

    # Create a ColumnDataSource for Bokeh
    source = ColumnDataSource(
        data=dict(x=embedding[:, 0], y=embedding[:, 1], label=source_df["filename"])
    )

    # Define the hover tool
    hover = HoverTool(tooltips=[("File", "@label"), ("(x,y)", "($x, $y)")])

    # Create a new plot with tools
    p = figure(
        tools=[hover, "pan", "wheel_zoom", "box_zoom", "reset", "save"],
        title="Interactive UMAP of Cytometry Data",
        x_axis_label="UMAP Dimension 1",
        y_axis_label="UMAP Dimension 2",
    )

    # Add a scatter renderer with data from the source
    p.scatter("x", "y", source=source, legend_label="Data Points", alpha=0.6, size=5)

    output_file(output_path, title="Interactive UMAP of Cytometry Data")
    save(p)
    logger.info(f"Interactive plot saved successfully to {output_path}")
