#!/bin/bash

# ==============================================================================
# SQL SERVER SAMPLE DATABASE DEPLOYMENT TOOL (ENTRY POINT)
# ==============================================================================
# Description:
#   This is the primary execution script (The Playbook). It orchestrates 
#   the deployment of specific datasets using the 'utility.sh' library.
#
# Prerequisite:
#   - Ensure 'utility.sh' is in the same directory.
#   - Ensure '.env' contains 'MSSQL_SA_PASSWORD'.
#
# Execution:
#   Run this script directly from the terminal:
#     ./usage.sh
#
# Workflow:
#   1. Loads environment variables and utility functions.
#   2. Downloads .bak files to this script's directory.
#   3. Restores them to the SQL Server 2025 container.
#   4. Deletes temporary .bak files from host and container volume.
# ==============================================================================

# get the directory where the script lives
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# 1. Import the utility functions
# 'source' (or '.') makes the functions from utility.sh available here
source "$SCRIPT_DIR/utility.sh"

# 2. Load the environment
# We do this first so we don't waste time if the config is broken
if ! load_config; then
    echo "Configuration failed. Check your .env file."
    exit 1
fi

# 3. Define and Deploy
AW_URL="https://github.com/Microsoft/sql-server-samples/releases/download/adventure-works/AdventureWorks2022.bak"

deploy_sample_db "$AW_URL" "AdventureWorks"
