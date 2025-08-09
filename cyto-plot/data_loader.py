import pandas as pd
import readfcs
from pathlib import Path
from logger import logger
from typing import Optional
import time


def load_fcs_data(
    data_dir: str, memory, max_events_per_file: Optional[int] = None
) -> pd.DataFrame:
    """
    Loads all .fcs files from a directory, combines them, and caches the result.
    Optionally samples a random subset of events from each file.
    """

    # The actual function to be cached by joblib
    @memory.cache
    def _cached_load(directory, max_events):
        logger.info(f"Loading .fcs files from '{directory}'...")
        if max_events is not None and max_events > 0:
            logger.info(f"Sampling a maximum of {max_events} events per file.")

        fcs_files = list(Path(directory).glob("*.fcs"))
        if not fcs_files:
            logger.error(f"No .fcs files found in directory: {directory}")
            raise ValueError(f"No .fcs files found in directory: {directory}")

        logger.info(f"Found {len(fcs_files)} .fcs files to process")
        all_data = []
        for fcs_file in fcs_files:
            try:
                logger.debug(f"Reading file: {fcs_file.name}")
                adata = readfcs.read(str(fcs_file))
                df = adata.to_df()

                # Sample data if max_events is set
                if max_events is not None and max_events > 0 and len(df) > max_events:
                    logger.debug(
                        f"Sampling {max_events} events from {fcs_file.name} (original size: {len(df)})"
                    )
                    df = df.sample(n=max_events, random_state=int(time.time()))
                else:
                    logger.debug(
                        f"Using all {len(df)} events from {fcs_file.name} (no sampling applied)"
                    )

                # Add filename for labeling and tracking origin
                df["filename"] = fcs_file.name
                all_data.append(df)
                logger.debug(
                    f"Successfully loaded {len(df)} events from {fcs_file.name}"
                )
            except Exception as e:
                logger.warning(f"Could not read {fcs_file.name}: {e}")

        if not all_data:
            logger.error("No FCS files were successfully loaded")
            raise ValueError("No FCS files were successfully loaded.")

        logger.info("Combining loaded files into a single DataFrame...")
        combined_df = pd.concat(all_data, ignore_index=True)
        logger.info(
            f"Successfully combined {len(combined_df)} total events from {len(all_data)} files"
        )
        return combined_df

    # Call the cached function
    return _cached_load(data_dir, max_events_per_file)
