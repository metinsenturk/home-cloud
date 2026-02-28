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


def download_strategies() -> bool:
    """
    Download official freqtrade strategies from GitHub via ZIP file.
    
    Process:
        1. Check if strategies folder already has .py files
        2. If it does, skip download (user already has strategies)
        3. If empty, downloads the freqtrade-strategies repo as ZIP
        4. Extracts the ZIP file
        5. Copies .py strategy files from the downloaded repo
        6. Cleans up temporary files
    
    Returns:
        True if successful or skipped (strategies exist), False on error
    """
    try:
        # Check if strategies already exist
        existing_strategies = list(STRATEGIES_DIR.glob("*.py"))
        if existing_strategies:
            log(f"Found {len(existing_strategies)} existing strategies. Skipping download.")
            return True
        
        log("Downloading official freqtrade strategies...")
        
        # Step 1: Download ZIP from GitHub
        zip_path = TEMP_DIR / "freqtrade-strategies.zip"
        extract_path = TEMP_DIR / "freqtrade-strategies-main"
        strategies_src = extract_path / "user_data" / "strategies"
        
        try:
            log("Fetching repository...")
            urllib.request.urlretrieve(REPO_ZIP_URL, str(zip_path))
        except urllib.error.URLError as e:
            log(f"Warning: Failed to download repository: {e}", "[strategy-downloader]")
            return False
        
        # Step 2: Extract ZIP
        try:
            log("Extracting strategies...")
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(str(TEMP_DIR))
        except zipfile.BadZipFile as e:
            log(f"Warning: Failed to extract ZIP: {e}", "[strategy-downloader]")
            return False
        
        # Step 3: Copy downloaded strategies
        if not strategies_src.exists():
            log("Warning: strategies folder not found in downloaded repo", "[strategy-downloader]")
            return False
        
        strategy_files = list(strategies_src.glob("*.py"))
        if not strategy_files:
            log("Warning: No .py files found in downloaded strategies folder", "[strategy-downloader]")
            return False
        
        log(f"Copying {len(strategy_files)} strategy files...")
        for strategy_file in strategy_files:
            try:
                dest_file = STRATEGIES_DIR / strategy_file.name
                shutil.copy2(strategy_file, dest_file)
                log(f"  ✓ Copied {strategy_file.name}")
            except Exception as e:
                log(f"  ✗ Failed to copy {strategy_file.name}: {e}", "[strategy-downloader]")
        
        log(f"Successfully installed {len(strategy_files)} official strategies")
        return True
        
    except Exception as e:
        log(f"Warning: Unexpected error during strategy download: {e}", "[strategy-downloader]")
        return False
    
    finally:
        # Cleanup temporary files
        try:
            zip_path = TEMP_DIR / "freqtrade-strategies.zip"
            if zip_path.exists():
                zip_path.unlink()
            
            extract_path = TEMP_DIR / "freqtrade-strategies-main"
            if extract_path.exists():
                shutil.rmtree(extract_path, ignore_errors=True)
        except Exception as e:
            log(f"Warning: Failed to cleanup temporary files: {e}", "[strategy-downloader]")
