import pandas as pd
import numpy as np
from bokeh.plotting import figure, save, output_file
from bokeh.models import HoverTool, ColumnDataSource, CategoricalColorMapper
from bokeh.palettes import Category20_20
from pathlib import Path
from logger import logger
from itertools import cycle


def generate_interactive_plot(
    embedding: np.ndarray,
    source_df: pd.DataFrame,
    cluster_labels: np.ndarray,
    output_path: Path,
    point_alpha: float = 0.6,
    point_size: int = 2,
    percentile: int = 99,
    margin_percent: int = 10,
):
    """
    Generates an interactive Bokeh plot from the UMAP embedding and saves it to HTML.
    Colors points based on cluster labels and includes cluster sizes in the legend.
    """
    logger.info(f"Generating interactive plot and saving to {output_path}...")

    # Create a DataFrame for plotting
    plot_df = pd.DataFrame(embedding, columns=("x", "y"))
    plot_df["label"] = source_df["filename"]
    plot_df["cluster"] = cluster_labels.astype(
        str
    )  # Convert labels to string for categorical mapping

    # Sort clusters by size (number of points) in descending order
    cluster_counts = plot_df["cluster"].value_counts()
    unique_clusters = cluster_counts.index.tolist()
    logger.info(
        f"Found {len(unique_clusters)} unique clusters. The largest is cluster '{unique_clusters[0]}' with {cluster_counts.iloc[0]} points."
    )

    # Create legend labels with cluster sizes
    legend_labels_map = {
        label: f"{label} ({count})" for label, count in cluster_counts.items()
    }
    plot_df["legend_label"] = plot_df["cluster"].map(legend_labels_map)

    source = ColumnDataSource(plot_df)

    # Define the hover tool
    hover = HoverTool(
        tooltips=[
            ("File", "@label"),
            ("Cluster", "@cluster"),
          #  ("(x,y)", "($x, $y)"),
        ]
    )

    # Create a color palette, cycling if more clusters than available colors
    num_clusters = len(unique_clusters)
    if num_clusters > len(Category20_20):
        logger.warning(
            f"More clusters ({num_clusters}) than available colors ({len(Category20_20)}). Colors will be recycled."
        )
        color_cycle = cycle(Category20_20)
        palette = [next(color_cycle) for _ in range(num_clusters)]
    else:
        # Use a palette from Bokeh that is at least 3 colors long
        palette = Category20_20[: max(3, num_clusters)]

    color_mapper = CategoricalColorMapper(factors=unique_clusters, palette=palette)

    # Create a new plot with tools
    p = figure(
        tools=[hover, "pan", "wheel_zoom", "box_zoom", "reset", "save"],
        title="Interactive UMAP of Cytometry Data with DBSCAN Clustering",
        x_axis_label="UMAP Dimension 1",
        y_axis_label="UMAP Dimension 2",
    )

    # Calculate plot extends to show the specified percentile of points plus a margin
    lower_quantile = (100 - percentile) / 2 / 100
    upper_quantile = (percentile + (100 - percentile) / 2) / 100

    x_range_core = plot_df["x"].quantile([lower_quantile, upper_quantile])
    y_range_core = plot_df["y"].quantile([lower_quantile, upper_quantile])

    x_margin = (x_range_core.iloc[1] - x_range_core.iloc[0]) * (margin_percent / 100)
    y_margin = (y_range_core.iloc[1] - y_range_core.iloc[0]) * (margin_percent / 100)

    p.x_range.start = x_range_core.iloc[0] - x_margin
    p.x_range.end = x_range_core.iloc[1] + x_margin
    p.y_range.start = y_range_core.iloc[0] - y_margin
    p.y_range.end = y_range_core.iloc[1] + y_margin

    # Set plot dimensions to fill the available space
    p.sizing_mode = "stretch_both"

    # Add a scatter renderer with data from the source, colored by cluster
    p.scatter(
        "x",
        "y",
        source=source,
        fill_color={"field": "cluster", "transform": color_mapper},
        line_color=None,
        legend_field="legend_label",
        alpha=point_alpha,
        size=point_size,
    )

    p.legend.title = "Cluster (size)"
    p.legend.location = "top_left"
    p.legend.click_policy = "hide"

    output_file(output_path, title="Interactive UMAP of Cytometry Data")
    save(p)
    logger.info(f"Interactive plot saved successfully to {output_path}")
