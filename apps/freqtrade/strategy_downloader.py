#!/usr/bin/env python3
"""
Freqtrade strategy downloader helper.

Downloads official freqtrade strategies from:
    https://github.com/freqtrade/freqtrade-strategies/tree/main/user_data/strategies

This module downloads the official freqtrade strategies repository and copies
strategy files into the user_data/strategies directory. This is optional and can
be enabled/disabled via a flag in entrypoint.py.

Why use this?
    - Official strategies are well-tested and maintained by the freqtrade team
    - Provides a good starting point for developing your own strategies
    - Can be used as reference implementations
    - Downloaded on first start if enabled

Implementation:
    - Uses urllib + zipfile (Python stdlib only, no external dependencies)
    - Downloads ZIP of main branch from GitHub
    - Extracts only the strategies folder
    - Skips if strategies already exist (doesn't overwrite custom strategies)
"""

import urllib.request
import urllib.error
import zipfile
import shutil
from pathlib import Path

# Module-level configuration
REPO_ZIP_URL = "https://github.com/freqtrade/freqtrade-strategies/archive/refs/heads/main.zip"
USER_DATA_DIR = Path("/freqtrade/user_data")
STRATEGIES_DIR = USER_DATA_DIR / "strategies"
TEMP_DIR = Path("/tmp")

# Log prefix for this module
LOG_PREFIX = "[strategy-downloader]"


def log(message: str, prefix: str = LOG_PREFIX) -> None:
    """Print a prefixed log message."""
    print(f"{prefix} {message}", flush=True)


def check_existing_strategies() -> bool:
    """
    Check if strategies already exist in the strategies directory.
    
    Returns:
        True if strategies exist (skip download), False otherwise
    """
    existing_strategies = list(STRATEGIES_DIR.glob("*.py"))
    if existing_strategies:
        log(f"Found {len(existing_strategies)} existing strategies. Skipping download.")
        return True
    return False


def download_zip(zip_path: Path) -> bool:
    """
    Download the freqtrade-strategies repository as a ZIP file from GitHub.
    
    Args:
        zip_path: Path where to save the downloaded ZIP file
    
    Returns:
        True if successful, False on error
    """
    try:
        log("Fetching repository...")
        urllib.request.urlretrieve(REPO_ZIP_URL, str(zip_path))
        return True
    except urllib.error.URLError as e:
        log(f"Warning: Failed to download repository: {e}")
        return False


def extract_zip(zip_path: Path, extract_path: Path) -> bool:
    """
    Extract the downloaded ZIP file to a temporary directory.
    
    Args:
        zip_path: Path to the ZIP file to extract
        extract_path: Path where to extract the contents
    
    Returns:
        True if successful, False on error
    """
    try:
        log("Extracting strategies...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(str(extract_path))
        return True
    except zipfile.BadZipFile as e:
        log(f"Warning: Failed to extract ZIP: {e}")
        return False


def copy_strategies(strategies_src: Path) -> bool:
    """
    Copy strategy files from the extracted repository to the user_data/strategies directory.
    
    Args:
        strategies_src: Path to the strategies folder in the extracted repository
    
    Returns:
        True if successful, False on error
    """
    if not strategies_src.exists():
        log("Warning: strategies folder not found in downloaded repo")
        return False
    
    strategy_files = list(strategies_src.glob("*.py"))
    if not strategy_files:
        log("Warning: No .py files found in downloaded strategies folder")
        return False
    
    log(f"Copying {len(strategy_files)} strategy files...")
    for strategy_file in strategy_files:
        try:
            dest_file = STRATEGIES_DIR / strategy_file.name
            shutil.copy2(strategy_file, dest_file)
            log(f"  ✓ Copied {strategy_file.name}")
        except Exception as e:
            log(f"  ✗ Failed to copy {strategy_file.name}: {e}")
    
    log(f"Successfully installed {len(strategy_files)} official strategies")
    return True


def cleanup_temp_files(zip_path: Path, extract_path: Path) -> None:
    """
    Clean up temporary files created during download and extraction.
    
    Args:
        zip_path: Path to the downloaded ZIP file to delete
        extract_path: Path to the extracted directory to delete
    """
    try:
        if zip_path.exists():
            zip_path.unlink()
        
        if extract_path.exists():
            shutil.rmtree(extract_path, ignore_errors=True)
    except Exception as e:
        log(f"Warning: Failed to cleanup temporary files: {e}")


def download_strategies() -> bool:
    """
    Download official freqtrade strategies from GitHub via ZIP file.
    
    Orchestrates the complete strategy download workflow:
        1. Check if strategies already exist (skip if they do)
        2. Download the freqtrade-strategies repository as ZIP from GitHub
        3. Extract the ZIP file to a temporary directory
        4. Copy strategy files to the user_data/strategies directory
        5. Clean up temporary files
    
    Returns:
        True if successful or skipped (strategies exist), False on error
    """
    # Check if strategies already exist
    if check_existing_strategies():
        return True
    
    log("Downloading official freqtrade strategies...")
    
    # Setup paths
    zip_path = TEMP_DIR / "freqtrade-strategies.zip"
    extract_path = TEMP_DIR / "freqtrade-strategies-main"
    strategies_src = extract_path / "user_data" / "strategies"
    
    try:
        # Download ZIP from GitHub
        if not download_zip(zip_path):
            return False
        
        # Extract ZIP
        if not extract_zip(zip_path, extract_path):
            return False
        
        # Copy strategy files
        if not copy_strategies(strategies_src):
            return False
        
        return True
        
    except Exception as e:
        log(f"Warning: Unexpected error during strategy download: {e}")
        return False
    
    finally:
        # Always cleanup temporary files
        cleanup_temp_files(zip_path, extract_path)
