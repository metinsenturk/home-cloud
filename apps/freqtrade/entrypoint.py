#!/usr/bin/env python3
"""
Freqtrade entrypoint initialization script.

This script overrides the freqtradeorg/freqtrade image's default entrypoint to add
automated initialization on first start. The Docker container execution flow is:

  1. Docker starts the container
  2. entrypoint: python3 /entrypoint.py  (this script runs)
  3. This script receives all command args via sys.argv
  4. Script checks if config.json exists; if not, initializes it
  5. Script then launches freqtrade with the original command args via subprocess.run()

Why override the entrypoint?
  - The freqtradeorg/freqtrade image expects config.json to exist before starting
  - It does NOT auto-initialize on first run (you must manually run create-userdir + new-config)
  - This script automates that process, so the container "just works" on first start

How it works:
  - docker-compose.yml has TWO fields:
      entrypoint: python3 /entrypoint.py          <- Replaces image's default entrypoint
      command: freqtrade trade --config ...       <- Passed as arguments to entrypoint
  - Docker merges them: python3 /entrypoint.py freqtrade trade --config ...
  - This script receives them via sys.argv[1:]
  - After initialization, script runs: subprocess.run(['freqtrade', 'trade', '--config', ...])

Automatically initializes freqtrade on first start:
  1. Creates the user directory structure (strategies/, backtest_results/, data/, logs/)
  2. Generates a new config.json with defaults
  3. Updates the exchange from binance to kraken (avoids HTTP 451 geo-restrictions)
  4. Launches the freqtrade trading bot with provided arguments

Usage:
    python3 /entrypoint.py [freqtrade_args...]
    
Example in docker-compose.yml:
    entrypoint: python3 /entrypoint.py
    command: freqtrade trade --config user_data/config.json --strategy SampleStrategy
    
Example in docker run:
    docker run freqtradeorg/freqtrade:latest \
      python3 /entrypoint.py freqtrade show-config
"""

import subprocess
import sys
import json
import os
from pathlib import Path
from strategy_downloader import download_strategies

# Module-level configuration
USER_DATA_DIR = Path("/freqtrade/user_data")
CONFIG_FILE = USER_DATA_DIR / "config.json"
CONFIG_PATH_ARG = str(CONFIG_FILE)

# Log prefix for entrypoint messages
LOG_PREFIX = "[entrypoint]"

# === STRATEGY DOWNLOAD CONFIGURATION ===
# Set to True to automatically download official freqtrade strategies on first start
# If True and no strategies exist, entrypoint will fetch them from:
#   https://github.com/freqtrade/freqtrade-strategies/tree/main/user_data/strategies
# Downloaded strategies provide well-tested reference implementations for backtesting/trading
# Change to False if you want to manage strategies manually
ENABLE_STRATEGY_DOWNLOAD = True


def log(message: str) -> None:
    """Print a prefixed log message."""
    print(f"{LOG_PREFIX} {message}", flush=True)


def run_command(cmd: list, description: str) -> bool:
    """
    Run a shell command and handle errors gracefully.
    
    Args:
        cmd: List of command arguments (for subprocess.run)
        description: Human-readable description of the command
        
    Returns:
        True if successful, False otherwise
    """
    try:
        log(f"Running: {description}...")
        result = subprocess.run(cmd, check=True, capture_output=False, text=True)
        return True
    except subprocess.CalledProcessError as e:
        log(f"Warning: {description} failed with exit code {e.returncode}")
        return False
    except Exception as e:
        log(f"Warning: {description} encountered an error: {e}")
        return False


def create_user_directory() -> bool:
    """
    Create the freqtrade user directory structure.
    
    Runs: freqtrade create-userdir --userdir /freqtrade/user_data --reset
    
    Returns:
        True if successful, False otherwise
    """
    cmd = ["freqtrade", "create-userdir", "--userdir", str(USER_DATA_DIR), "--reset"]
    return run_command(cmd, "Creating user directory structure")


def generate_config() -> bool:
    """
    Generate a new config.json with default values.
    
    Runs: freqtrade new-config -c user_data/config.json
    Pipes default answers (Enter key presses) to auto-accept all prompts.
    
    Returns:
        True if successful, False otherwise
    """
    cmd = ["freqtrade", "new-config", "-c", CONFIG_PATH_ARG]
    
    # Prepare input: 20 newlines to auto-accept all prompts
    default_input = "\n" * 20
    
    try:
        log(f"Generating config.json with defaults...")
        result = subprocess.run(
            cmd,
            input=default_input,
            text=True,
            check=False,  # Don't raise on non-zero exit
            capture_output=False,
        )
        # new-config may exit with 1 on some prompts, but file is still created
        return CONFIG_FILE.exists()
    except Exception as e:
        log(f"Warning: Config generation encountered an error: {e}")
        return CONFIG_FILE.exists()


def update_exchange_to_kraken() -> bool:
    """
    Update config.json to use kraken exchange instead of binance.
    
    Purpose: Avoids HTTP 451 "Service unavailable from restricted location" 
    errors when connecting to binance API.
    
    Returns:
        True if successful, False otherwise
    """
    if not CONFIG_FILE.exists():
        log("Warning: config.json not found, skipping exchange update")
        return False
    
    try:
        log("Updating exchange to kraken...")
        
        # Read config
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            config = json.load(f)
        
        # Update exchange if it's binance
        if config.get("exchange", {}).get("name") == "binance":
            config["exchange"]["name"] = "kraken"
            
            # Write updated config
            with open(CONFIG_FILE, "w", encoding="utf-8") as f:
                json.dump(config, f, indent=4)
            
            log("Switched exchange from binance to kraken")
            return True
        else:
            exchange_name = config.get("exchange", {}).get("name", "unknown")
            log(f"Exchange is already '{exchange_name}', no update needed")
            return True
            
    except Exception as e:
        log(f"Warning: Could not update exchange in config: {e}")
        return False


def initialize_if_needed() -> None:
    """
    Check if config.json exists. If not, run full initialization.
    """
    if CONFIG_FILE.exists():
        log(f"config.json found at {CONFIG_FILE}. Skipping initialization.")
        return
    
    log(f"config.json not found. Running first-time setup...")
    
    # Step 1: Create user directory structure
    if not create_user_directory():
        log("Failed to create user directory. Continuing anyway...")
    
    # Step 2: Generate config with defaults
    if not generate_config():
        log("Failed to generate config. Continuing anyway...")
    
    # Step 3: Update exchange to avoid geo-restrictions
    if not update_exchange_to_kraken():
        log("Failed to update exchange. Continuing anyway...")
    
    # Step 4: Download official strategies (optional, controlled by ENABLE_STRATEGY_DOWNLOAD flag)
    if ENABLE_STRATEGY_DOWNLOAD:
        if not download_strategies():
            log("Failed to download strategies. Continuing anyway...")
    else:
        log("Strategy download disabled (ENABLE_STRATEGY_DOWNLOAD=False)")
    
    log("First-time setup complete.")


def main() -> int:
    """
    Main entry point: initialize config if needed, then launch freqtrade.
    
    Architecture explanation:
    -------------------------
    This function handles the entrypoint override that allows freqtrade to auto-initialize.
    
    When docker-compose.yml has:
        entrypoint: python3 /entrypoint.py
        command: freqtrade trade --config user_data/config.json --strategy SampleStrategy
    
    Docker merges them into a single command:
        python3 /entrypoint.py freqtrade trade --config user_data/config.json --strategy SampleStrategy
    
    So this script receives:
        sys.argv[0] = '/entrypoint.py'
        sys.argv[1:] = ['freqtrade', 'trade', '--config', 'user_data/config.json', '--strategy', 'SampleStrategy']
    
    We then:
        1. Call initialize_if_needed() to set up config if missing
        2. Extract sys.argv[1:] which contains the original freqtrade command + args
        3. Launch freqtrade using subprocess.run() with those args
        4. Return freqtrade's exit code to Docker
    
    Returns:
        Exit code from freqtrade process (0 = success, non-zero = error)
    """
    initialize_if_needed()
    
    # Extract freqtrade command and args that were passed to this script
    # sys.argv[1:] contains everything after 'python3 /entrypoint.py'
    log("Starting freqtrade...")
    cmd = sys.argv[1:]  # All args passed to this script via docker-compose command
    
    if not cmd:
        log("Error: No freqtrade command provided. Use: python3 /entrypoint.py freqtrade [args...]")
        return 1
    
    try:
        # Launch the freqtrade binary with the command and args we received
        # subprocess.run() waits for freqtrade to exit and captures its exit code
        result = subprocess.run(cmd, check=False)
        return result.returncode  # Return freqtrade's exit code to Docker
    except Exception as e:
        log(f"Error launching freqtrade: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
