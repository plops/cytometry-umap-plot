import pandas as pd
import cupy as cp
from cuml import UMAP
from cuml.cluster import DBSCAN
from logger import logger


def run_gpu_umap(
    data: pd.DataFrame, umap_params, memory, train_size: int = -1
) -> cp.ndarray:
    """
    Performs UMAP on the GPU using cuml and caches the result.
    If train_size is specified and is smaller than the dataset, UMAP is trained
    on a random subset of data and then used to transform the full dataset.
    """

    @memory.cache
    def _cached_umap(data_to_embed, train_subset_size, **params):
        logger.info("Performing UMAP on GPU with cuML...")
        # Convert pandas DataFrame to CuPy array for cuML
        gpu_data = cp.asarray(data_to_embed.values)
        logger.info(f"Data shape for UMAP: {gpu_data.shape}")
        logger.debug(f"UMAP parameters: {params}")

        cuml_umap = UMAP(**params)

        if 0 < train_subset_size < len(gpu_data):
            logger.info(
                f"Training UMAP on a random subset of {train_subset_size} points..."
            )
            # Create a random subset for training
            cp.random.seed(42)
            train_indices = cp.random.choice(
                len(gpu_data), train_subset_size, replace=False
            )
            train_data = gpu_data[train_indices]

            logger.info("Starting UMAP fitting...")
            cuml_umap.fit(train_data)
            logger.info("UMAP fitting completed. Now transforming all points...")
            embedding = cuml_umap.transform(gpu_data)
        else:
            logger.info("Starting UMAP computation (fit and transform)...")
            embedding = cuml_umap.fit_transform(gpu_data)

        logger.info(f"UMAP computation completed. Embedding shape: {embedding.shape}")

        # Convert result back to a CPU-based NumPy array for plotting and storage
        return cp.asnumpy(embedding)

    # Call the cached function with parameters from the config
    return _cached_umap(data, train_size, **vars(umap_params))


def run_gpu_dbscan(embedding: cp.ndarray, dbscan_params, memory) -> cp.ndarray:
    """
    Performs DBSCAN on the GPU using cuml on a given embedding and caches the result.
    """

    @memory.cache
    def _cached_dbscan(data_to_cluster, **params):
        logger.info("Performing DBSCAN on GPU with cuML...")
        logger.debug(f"DBSCAN parameters: {params}")

        # Data is already a CuPy array from UMAP
        cuml_dbscan = DBSCAN(**params)
        logger.info("Starting DBSCAN computation...")
        labels = cuml_dbscan.fit_predict(data_to_cluster)
        logger.info("DBSCAN computation completed.")

        num_clusters = len(cp.unique(labels))
        logger.debug(f"Number of clusters found: {num_clusters}")

        # Convert result back to a CPU-based NumPy array
        return cp.asnumpy(labels)

    # Call the cached function with parameters from the config
    return _cached_dbscan(embedding, **vars(dbscan_params))
