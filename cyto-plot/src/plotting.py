import pandas as pd
import numpy as np
import umap.plot
from bokeh.plotting import save, output_file
from pathlib import Path

def generate_interactive_plot(
        embedding: np.ndarray,
        source_df: pd.DataFrame,
        output_path: Path
):
    """
    Generates an interactive Bokeh plot from the UMAP embedding and saves it to HTML.
    """
    print(f"Generating interactive plot and saving to {output_path}...")

    # umap.plot.interactive requires a UMAP object. We can create a dummy object
    # that just holds our pre-computed embedding.
    class DummyUMAP:
        def __init__(self, embedding):
            self.embedding_ = embedding

    dummy_mapper = DummyUMAP(embedding)

    # Use the 'filename' column for coloring points and for hover information
    labels = source_df['filename']
    hover_data = pd.DataFrame({
        'x': embedding[:, 0],
        'y': embedding[:, 1],
        'File': labels
    })

    p = umap.plot.interactive(
        dummy_mapper,
        labels=labels,
        hover_data=hover_data,
        point_size=2
    )

    output_file(output_path, title="Interactive UMAP of Cytometry Data")
    save(p)