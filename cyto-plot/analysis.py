import pandas as pd
import cupy as cp
from cuml.manifold import UMAP

def run_gpu_umap(data: pd.DataFrame, umap_params, memory) -> cp.ndarray:
    """
    Performs UMAP on the GPU using cuml and caches the result.
    """
    @memory.cache
    def _cached_umap(data_to_embed, **params):
        print("Performing UMAP on GPU with cuML...")
        # Convert pandas DataFrame to CuPy array for cuML
        gpu_data = cp.asarray(data_to_embed.values)
        print(f"Data shape for UMAP: {gpu_data.shape}")
        print(f"Parameters for UMAP: {params}")
        cuml_umap = UMAP(**params)
        embedding = cuml_umap.fit_transform(gpu_data)

        # Convert result back to a CPU-based NumPy array for plotting and storage
        return cp.asnumpy(embedding)

    # Call the cached function with parameters from the config
    return _cached_umap(data, **vars(umap_params))