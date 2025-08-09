import os
import pandas as pd
import readfcs
from pathlib import Path

def load_fcs_data(data_dir: str, memory) -> pd.DataFrame:
    """
    Loads all .fcs files from a directory, combines them, and caches the result.
    """
    # The actual function to be cached by joblib
    @memory.cache
    def _cached_load(directory):
        print(f"Loading .fcs files from '{directory}'...")
        fcs_files = list(Path(directory).glob('*.fcs'))
        if not fcs_files:
            raise ValueError(f"No .fcs files found in directory: {directory}")

        all_data = []
        for fcs_file in fcs_files:
            try:
                adata = readfcs.read(str(fcs_file))
                df = adata.to_df()
                # Add filename for labeling and tracking origin
                df['filename'] = fcs_file.name
                all_data.append(df)
            except Exception as e:
                print(f"Warning: Could not read {fcs_file.name}: {e}")

        if not all_data:
            raise ValueError("No FCS files were successfully loaded.")

        print("Combining loaded files into a single DataFrame...")
        return pd.concat(all_data, ignore_index=True)

    # Call the cached function
    return _cached_load(data_dir)