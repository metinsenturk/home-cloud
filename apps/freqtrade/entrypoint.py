#!/usr/bin/env python3
"""
Freqtrade entrypoint initialization script.

Automatically initializes freqtrade user directory and config on first start.
If config.json is missing, this script:
  1. Creates the user directory structure
  2. Generates a new config.json with defaults
  3. Updates the exchange from binance to kraken (avoids geo-restrictions)
  4. Launches the freqtrade trading bot

Usage:
    python3 /entrypoint.py [freqtrade_args...]
    
Example in docker-compose.yml:
    entrypoint: python3 /entrypoint.py
    command: freqtrade trade --config user_data/config.json --strategy SampleStrategy
"""

import subprocess
import sys
import json
import os
from pathlib import Path

# Module-level configuration
USER_DATA_DIR = Path("/freqtrade/user_data")
CONFIG_FILE = USER_DATA_DIR / "config.json"
CONFIG_PATH_ARG = str(CONFIG_FILE)

# Log prefix for entrypoint messages
LOG_PREFIX = "[entrypoint]"


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
    
    log("First-time setup complete.")


def main() -> int:
    """
    Main entry point: initialize config if needed, then launch freqtrade.
    
    Returns:
        Exit code from freqtrade process
    """
    initialize_if_needed()
    
    # Build freqtrade command from remaining arguments
    log("Starting freqtrade...")
    cmd = sys.argv[1:]  # All args passed to this script
    
    if not cmd:
        log("Error: No freqtrade command provided. Use: python3 /entrypoint.py freqtrade [args...]")
        return 1
    
    try:
        # Replace this process with freqtrade (exec-style)
        result = subprocess.run(cmd, check=False)
        return result.returncode
    except Exception as e:
        log(f"Error launching freqtrade: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
