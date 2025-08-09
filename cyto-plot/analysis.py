import pandas as pd
import cupy as cp
from cuml import UMAP
from logger import logger


def run_gpu_umap(data: pd.DataFrame, umap_params, memory) -> cp.ndarray:
    """
    Performs UMAP on the GPU using cuml and caches the result.
    """

    @memory.cache
    def _cached_umap(data_to_embed, **params):
        logger.info("Performing UMAP on GPU with cuML...")
        # Convert pandas DataFrame to CuPy array for cuML
        gpu_data = cp.asarray(data_to_embed.values)
        logger.info(f"Data shape for UMAP: {gpu_data.shape}")
        logger.debug(f"UMAP parameters: {params}")

        cuml_umap = UMAP(**params)
        logger.info("Starting UMAP computation...")
        embedding = cuml_umap.fit_transform(gpu_data)
        logger.info(f"UMAP computation completed. Embedding shape: {embedding.shape}")

        # Convert result back to a CPU-based NumPy array for plotting and storage
        return cp.asnumpy(embedding)

    # Call the cached function with parameters from the config
    return _cached_umap(data, **vars(umap_params))
