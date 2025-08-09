import sys
from pathlib import Path
from joblib import Memory

# Add the current directory to the Python path to allow imports
sys.path.append(str(Path(__file__).resolve().parent))

import config
import data_loader
import analysis
import plotting
from logger import setup_logger
import logging


def main_pipeline():
    """
    Orchestrates the full data analysis pipeline.
    """
    # 1. Load Configuration to get logging settings
    try:
        cfg = config.load_config()
    except Exception as e:
        logging.basicConfig(level=logging.ERROR)
        logging.error(f"Failed to load configuration: {e}")
        return

    # 2. Setup logging using configuration
    # Ensure output directory exists for the log file
    output_dir = Path(cfg.paths.output_dir)
    output_dir.mkdir(exist_ok=True)
    log_file = output_dir / cfg.logging.log_file
    log_level = getattr(logging, cfg.logging.level.upper(), logging.INFO)
    logger = setup_logger("cyto-plot", log_file=log_file, level=log_level)

    logger.info("Starting Cytometry Analysis Pipeline")

    try:
        # 3. Setup Caching directory
        logger.info("Setting up cache directory")
        Path(cfg.paths.cache_dir).mkdir(exist_ok=True)
        joblib_memory = Memory(cfg.paths.cache_dir, verbose=0)

        # 4. Load Data
        try:
            max_events = getattr(cfg.data_processing, "max_events_per_file", -1)
            if max_events == -1:
                max_events = None  # Use None to signify loading all events

            data_df = data_loader.load_fcs_data(
                cfg.paths.fcs_data_dir, joblib_memory, max_events_per_file=max_events
            )
            logger.info(
                f"Successfully loaded {len(data_df)} events from {data_df['filename'].nunique()} files"
            )
        except (ValueError, FileNotFoundError) as e:
            logger.error(f"Data loading failed: {e}")
            return

        # 5. Prepare Data for UMAP
        marker_columns = [
            col
            for col in data_df.columns
            if col not in cfg.data_processing.exclude_columns
        ]
        umap_data = data_df[marker_columns]
        logger.info(f"Using {len(marker_columns)} columns for UMAP analysis")
        logger.debug(f"Marker columns: {marker_columns}")

        # 6. Run UMAP for Clustering (higher-dimensional)
        clustering_embedding = analysis.run_gpu_umap(
            umap_data, cfg.umap_params_clustering, joblib_memory
        )

        # 7. Run DBSCAN for cluster analysis
        cluster_labels = analysis.run_gpu_dbscan(
            clustering_embedding, cfg.dbscan_params, joblib_memory
        )

        # 8. Run UMAP for Visualization (2D)
        visualization_embedding = analysis.run_gpu_umap(
            umap_data, cfg.umap_params_visualization, joblib_memory
        )

        # 9. Generate and Save Plot
        output_plot_path = output_dir / cfg.paths.plot_filename
        plotting.generate_interactive_plot(
            visualization_embedding,
            data_df,
            cluster_labels,
            output_plot_path,
            percentile=cfg.plot_settings.percentile,
            margin_percent=cfg.plot_settings.margin_percent,
        )

        logger.info(
            f"Pipeline completed successfully. Output saved to {output_plot_path}"
        )

    except Exception as e:
        logger.critical(f"Pipeline failed with unexpected error: {e}", exc_info=True)
        raise


if __name__ == "__main__":
    main_pipeline()
