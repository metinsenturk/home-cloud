#!/bin/bash

# ==============================================================================
# SQL SERVER DOCKER UTILITY LIBRARY
# ==============================================================================
# Description:
#   A collection of utility functions for automating the deployment of sample 
#   databases (AdventureWorks, etc.) into a SQL Server 2025 Docker container.
#
# Infrastructure:
#   - Container:    infra_mssql
#   - Data Volume:  Maps to /var/opt/mssql/data
#   - Backup Temp:  Maps to /var/opt/mssql/backup (created if missing)
#
# Requirements:
#   1. A running SQL Server Docker container.
#   2. A .env file in the same directory containing: MSSQL_SA_PASSWORD=your_password
#   3. Tools installed on host: curl, docker, awk.
#
# Usage:
#   In your main script:
#     source ./utility.sh
#     load_config
#     deploy_sample_db "https://url-to-bak/file.bak" "TargetDBName"
#
# Functions:
#   - load_config:      Sources .env and validates MSSQL_SA_PASSWORD.
#   - download_sample:  Downloads .bak file from a URL to the host.
#   - transfer_file:    Copies .bak from host to container and sets permissions.
#   - restore_db:       Restores DB using 'WITH MOVE' to map internal Linux paths.
#   - check_db_status:  Queries sys.databases to ensure state is ONLINE.
#   - cleanup_files:    Removes temporary .bak files from host and container.
#   - deploy_sample_db: The master orchestrator for the above steps.
#
# # Storage Behavior:
#   - Host:      Temporary. Files are downloaded to the script's directory and 
#                deleted by cleanup_files() after a successful restore.
#   - Container: Persistent. The database (.mdf/.ldf) is moved to /var/opt/mssql/data, 
#                which persists in your 'home_infra_mssql_data' volume.
# ==============================================================================

# --- STATIC CONFIGURATION SECTION ---

# The name or ID of your running SQL Server container
CONTAINER_NAME="infra_mssql"

# This directory exists by default in the image and is likely 
# where your 'home_infra_mssql_data' volume is mounted.
MSSQL_DATA_DIR="/var/opt/mssql/data"

# This folder usually DOES NOT exist by default. 
# The transfer_file function will create it inside the container.
# If this path is not explicitly mapped to a volume, files here 
# will be lost if the container is deleted (but the DB will stay in /data).
MSSQL_BACKUP_DIR="/var/opt/mssql/backup"

# Updated path to sqlcmd for SQL Server 2025 image
SQLCMD_PATH="/opt/mssql-tools18/bin/sqlcmd" # Updated path

# --- UTILITY FUNCTIONS ---

# Function: load_config
# Purpose: Locates and sources the .env file, then validates required variables.
# Usage: load_config
load_config() {
    # Get the directory where the script lives
    local script_dir=$(dirname "$(readlink -f "$0")")
    local env_path="$script_dir/.env"

    if [ -f "$env_path" ]; then
        # Load the variables into the current shell session
        source "$env_path"
    else
        echo "ERROR: Configuration file not found at $env_path"
        return 1
    fi

    # Check if the specific variable we need exists
    if [ -z "$MSSQL_SA_PASSWORD" ]; then
        echo "ERROR: MSSQL_SA_PASSWORD is not defined in $env_path"
        return 1
    fi

    return 0
}


# Function: transfer_file
# Purpose: Creates the backup directory if missing and copies the file.
# Usage: transfer_file "/path/to/backupfile.bak"
transfer_file() {
    local host_path=$1
    local filename=$(basename "$host_path")

    echo "--- Preparing container for transfer ---"
    
    # -p flag ensures no error if it exists, and creates it if it doesn't.
    # We use -u root to ensure we have permission to create folders in /var/opt/mssql
    docker exec -u root $CONTAINER_NAME mkdir -p $MSSQL_BACKUP_DIR
    
    echo "--- Transferring $filename to $MSSQL_BACKUP_DIR ---"
    docker cp "$host_path" "$CONTAINER_NAME:$MSSQL_BACKUP_DIR/$filename"
    
    # IMPORTANT: SQL Server runs as the 'mssql' user. 
    # 'docker cp' often brings host permissions over; this fix ensures SQL can read it.
    docker exec -u root $CONTAINER_NAME chown mssql:root "$MSSQL_BACKUP_DIR/$filename"
}

# Function: restore_db
# Purpose: Restores the DB and moves the internal files to the persistent data volume.
# Usage: restore_db "DatabaseName" "backupfile.bak"
restore_db() {
    local db_name=$1
    local bak_filename=$2
    local bak_path="$MSSQL_BACKUP_DIR/$bak_filename"

    echo "--- Analyzing logical file names for: $db_name ---"

    # 1. Define Discovery Command
    # We need the logical names of the data and log files stored inside the .bak
    local discovery_query="
        RESTORE FILELISTONLY 
        FROM DISK = '$bak_path';
    "

    # 1. Get Logical File Names
    # We extract logical names because the internal file paths in the .bak 
    # are Windows paths (C:\...) and will fail on Linux without 'WITH MOVE'.    
    # We use -h-1 to remove headers and -W to remove extra whitespace
    # We filter by the second column ($2): "D" for Data and "L" for Log.
    # This prevents the script from accidentally picking up dashed lines (---).
    local logical_data=$(
        docker exec -i "$CONTAINER_NAME" \
            "$SQLCMD_PATH" \
            -S localhost \
            -U sa \
            -P "$MSSQL_SA_PASSWORD" \
            -C \
            -h-1 \
            -W \
            -Q "$discovery_query" \
        | grep '^[[:alnum:]]' | awk '$2=="D" {print $1}' | head -n 1
    )

    local logical_log=$(
        docker exec -i "$CONTAINER_NAME" \
            "$SQLCMD_PATH" \
            -S localhost \
            -U sa \
            -P "$MSSQL_SA_PASSWORD" \
            -C \
            -h-1 \
            -W \
            -Q "RESTORE FILELISTONLY FROM DISK = '$bak_path';" \
        | grep '^[[:alnum:]]' | awk '$2=="L" {print $1}' | head -n 1
    )

    if [ -z "$logical_data" ] || [ -z "$logical_log" ]; then
        echo "Error: Could not retrieve logical names from $bak_filename"
        echo "DEBUG: Data: '$logical_data', Log: '$logical_log'"
        return 1
    fi

    # 2. Define the T-SQL Command in a clean, multiline format
    # This maps the internal logical files to the Linux file system paths
    # REPLACE: Overwrites if the DB already exists
    # STATS=5: Shows progress every 5%   
    local sql_query="
        RESTORE DATABASE [$db_name] 
        FROM DISK = '$bak_path' 
        WITH 
            MOVE '$logical_data' TO '$MSSQL_DATA_DIR/$db_name.mdf', 
            MOVE '$logical_log' TO '$MSSQL_DATA_DIR/${db_name}_log.ldf', 
            REPLACE, 
            STATS = 5;
    "

    echo "--- Executing Restore ---"
    
    # Execute the restore
    # 3. Run the command
    # We use -Q to execute the query and exit
    docker exec -i "$CONTAINER_NAME" \
        "$SQLCMD_PATH" \
        -S localhost \
        -U sa \
        -P "$MSSQL_SA_PASSWORD" \
        -C \
        -Q "$sql_query"
}

# Function: check_db_status
# Purpose: Verifies if the database is online and ready for queries.
# Usage: check_db_status "DatabaseName"
check_db_status() {
    local db_name=$1

    echo "--- Validating status for: $db_name ---"

    # 1. Define the query
    # state_desc provides a readable status (ONLINE, RESTORING, etc.)
    local status_query="
        SELECT state_desc 
        FROM sys.databases 
        WHERE name = '$db_name';
    "

    # 2. Execute and capture result
    local status=$(
        docker exec -i "$CONTAINER_NAME" \
            "$SQLCMD_PATH" \
            -S localhost \
            -U sa \
            -P "$MSSQL_SA_PASSWORD" \
            -C \
            -h-1 -W \
            -Q "$status_query" \
        | awk '{print $1}'
    )

    # 3. Logic Check
    if [ "$status" == "ONLINE" ]; then
        echo "SUCCESS: Database '$db_name' is ONLINE and ready."
        return 0
    else
        echo "ERROR: Database '$db_name' status is: ${status:-NOT_FOUND}"
        return 1
    fi
}

# Function: validate_file_size
# Purpose: Ensures a file exists and meets a minimum size requirement.
# Usage: validate_file_size "/path/to/file" 1000000 (size in bytes)
validate_file_size() {
    local file_path=$1
    local min_size=$2

    if [ ! -f "$file_path" ]; then
        echo "ERROR: File $file_path does not exist."
        return 1
    fi

    local actual_size=$(stat -c%s "$file_path")

    if [ "$actual_size" -lt "$min_size" ]; then
        echo "ERROR: File size check failed!"
        echo "Expected at least: $min_size bytes"
        echo "Actual size:     $actual_size bytes"
        return 1
    fi

    return 0
}

# Function: download_sample
# Purpose: Downloads a .bak file from a URL to the host machine, ensuring it's valid.
# Usage: download_sample "https://example.com/sample.bak" "/path/to/save/sample.bak"
download_sample() {
    local url=$1
    local destination=$2
    local min_expected_size=1000000 # 1MB

    echo "--- Checking for sample database ---"

    # 1. Check if the file already exists locally
    if [ -f "$destination" ]; then
        echo "File already exists at $destination. Validating size..."
        
        # 2. If it exists, make sure it's actually a valid file (not a 9-byte error)
        if validate_file_size "$destination" "$min_expected_size"; then
            echo "Existing file is valid. Skipping download."
            return 0
        else
            echo "Existing file is invalid/too small. Re-downloading..."
            rm "$destination"
        fi
    fi

    echo "Downloading from: $url"
    
    # 3. Perform the download if the file wasn't found or was invalid
    # -L: Follow redirects (important for GitHub/Microsoft links)
    # -f: Fail silently on server errors (4xx, 5xx) instead of saving an error page
    # -o: Save to specific filename
    # --create-dirs: Create local folder if it doesn't exist    
    if curl -Lf "$url" -o "$destination" --create-dirs; then
        if validate_file_size "$destination" "$min_expected_size"; then
            echo "SUCCESS: File downloaded and validated."
            return 0
        else
            return 1
        fi
    else
        echo "ERROR: Download failed. Check your internet connection or URL."
        return 1
    fi
}

# Function: cleanup_files
# Purpose: Deletes the backup file from the host and the container.
# Usage: cleanup_files "/path/to/backupfile.bak"
cleanup_files() {
    local host_path=$1
    local bak_filename=$(basename "$host_path")

    echo "--- Cleaning up temporary backup files ---"

    # 1. Remove from host
    if [ -f "$host_path" ]; then
        rm "$host_path"
        echo "Removed host file: $host_path"
    fi

    # 2. Remove from container (non-volume or temp backup dir)
    # We use -f to ignore error if file is already gone
    docker exec -u root "$CONTAINER_NAME" rm -f "$MSSQL_BACKUP_DIR/$bak_filename"
    echo "Removed container file: $MSSQL_BACKUP_DIR/$bak_filename"
}

# Function: deploy_sample_db
# Purpose: Orchestrates download, transfer, restore, validation, and cleanup.
# Usage: deploy_sample_db "https://example.com/sample.bak" "DatabaseName"
deploy_sample_db() {
    local url=$1
    local db_name=$2
    
    # Extract filename from URL (e.g., AdventureWorks2022.bak)
    local bak_filename=$(basename "$url")
    
    # Get the directory where the script itself is located
    local script_dir=$(dirname "$(readlink -f "$0")")
    local local_path="$script_dir/$bak_filename"

    echo "***************************************************"
    echo "STARTING DEPLOYMENT FOR: $db_name"
    echo "***************************************************"

    # Execute steps in sequence. 
    # If any step fails (returns 1), the chain stops.
    # Using '&&' ensures that if one command fails, 
    # the subsequent commands won't run, and we can 
    # capture the failure at the end.
    download_sample "$url" "$local_path" && \
    transfer_file "$local_path" && \
    restore_db "$db_name" "$bak_filename" && \
    check_db_status "$db_name" && \
    cleanup_files "$local_path"

    # Capture the exit status of the chain
    if [ $? -eq 0 ]; then
        echo "---------------------------------------------------"
        echo "SUCCESS: $db_name is ready for use."
        echo "---------------------------------------------------"
        return 0
    else
        echo "---------------------------------------------------"
        echo "FAILURE: Deployment failed for $db_name."
        echo "---------------------------------------------------"
        return 1
    fi
}
