import sys
from pathlib import Path
from joblib import Memory

# Add the src directory to the Python path to allow imports
sys.path.append(str(Path(__file__).resolve().parent / "src"))

from my_cyto_project import config, data_loader, analysis, plotting

def main_pipeline():
    """
    Orchestrates the full data analysis pipeline.
    """
    print("--- Starting Cytometry Analysis Pipeline ---")

    # 1. Load Configuration
    cfg = config.load_config()

    # 2. Setup Caching and output directories
    Path(cfg.paths.cache_dir).mkdir(exist_ok=True)
    Path(cfg.paths.output_dir).mkdir(exist_ok=True)
    joblib_memory = Memory(cfg.paths.cache_dir, verbose=0)

    # 3. Load Data
    # The function call is wrapped in a decorator, so caching is automatic. [3]
    try:
        data_df = data_loader.load_fcs_data(cfg.paths.fcs_data_dir, joblib_memory)
        print(f"Successfully loaded {len(data_df)} events from {data_df['filename'].nunique()} files.")
    except (ValueError, FileNotFoundError) as e:
        print(f"Error: {e}")
        return

    # 4. Prepare Data for UMAP
    marker_columns = [col for col in data_df.columns if col not in cfg.data_processing.exclude_columns]
    umap_data = data_df[marker_columns]
    print(f"Using {len(marker_columns)} columns for UMAP analysis.")

    # 5. Run UMAP
    embedding = analysis.run_gpu_umap(umap_data, cfg.umap_params, joblib_memory)

    # 6. Generate and Save Plot
    output_plot_path = Path(cfg.paths.output_dir) / cfg.paths.plot_filename
    plotting.generate_interactive_plot(embedding, data_df, output_plot_path)

    print(f"--- Pipeline Finished Successfully. Output at {output_plot_path} ---")


if __name__ == "__main__":
    main_pipeline()