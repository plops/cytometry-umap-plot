import yaml
from pathlib import Path
from types import SimpleNamespace

def load_config(config_path: str = 'config.yml') -> SimpleNamespace:
    """
    Loads a YAML configuration file and returns it as a SimpleNamespace object
    for easy attribute access (e.g., config.paths.data_dir).
    """
    path = Path(config_path)
    if not path.is_file():
        raise FileNotFoundError(f"Configuration file not found at: {path}")

    with open(path, 'r') as f:
        config_dict = yaml.safe_load(f)

    # Convert nested dictionaries to SimpleNamespace objects for dot notation access
    return SimpleNamespace(**{k: SimpleNamespace(**v) for k, v in config_dict.items()})