# ==============================================================================
# SQL SERVER DOCKER UTILITY LIBRARY (POWERSHELL VERSION)
# ==============================================================================

# --- STATIC CONFIGURATION SECTION ---
$ContainerName = "infra_mssql"
$MssqlDataDir  = "/var/opt/mssql/data"
$MssqlBackupDir = "/var/opt/mssql/backup"
$SqlCmdPath    = "/opt/mssql-tools18/bin/sqlcmd" # Used for docker exec calls

# Function: Load-Config
# Purpose: Simulates sourcing .env by reading the file and setting variables
function Load-Config {
    # Get the parent of the script's directory
    $ParentDir = Split-Path $PSScriptRoot -Parent
    $EnvPath = Join-Path $ParentDir ".env"
    if (Test-Path $EnvPath) {
        # Get-Content -Raw and a regex split is safer for passwords with special chars
        $Content = Get-Content $EnvPath -Raw
        if ($Content -match 'MSSQL_SA_PASSWORD\s*=\s*(.*)') {
            # Trim whitespace and any potential quotes around the password
            $script:MSSQL_SA_PASSWORD = $Matches[1].Trim().Trim('"').Trim("'")
            return $true
        }
    }
    
    Write-Error "ERROR: Could not find or parse MSSQL_SA_PASSWORD in .env"
    return $false
}

# Function: Get-LogicalNames
# Purpose: Uses PowerShell's string splitting to return an array of names
function Get-LogicalNames($Type, $RawOutput) {
    # Splits output into lines and scans for the Type (D/L)
    $Lines = $RawOutput -split "`n" | Where-Object { $_ -match '^[A-Z0-9]' }
    $Results = foreach ($Line in $Lines) {
        # Split by whitespace; LogicalName is $fields[0], Type is found by checking all fields
        $fields = $Line -split '\s+' | Where-Object { $_ -ne "" }
        if ($fields -contains $Type) { $fields[0] }
    }
    return $Results
}

# Function: Remove-Db
# Purpose: Drops database with connection termination
function Remove-Db($DbName) {
    Write-Host "--- Removing existing database: $DbName ---"
    $DropQuery = @"
        IF EXISTS (SELECT name FROM sys.databases WHERE name = '$DbName')
        BEGIN
            ALTER DATABASE [$DbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
            DROP DATABASE [$DbName];
        END
"@
    docker exec -i $ContainerName $SqlCmdPath -S localhost -U sa -P $script:MSSQL_SA_PASSWORD -C -Q $DropQuery
}

# Function: Restore-Db
# Purpose: Handles multi-file restores dynamically
function Restore-Db($DbName, $BakFilename) {
    $BakPath = "$MssqlBackupDir/$BakFilename"
    Write-Host "--- Analyzing logical file names for: $DbName ---"

    $DiscoveryQuery = "RESTORE FILELISTONLY FROM DISK = '$BakPath';"
    $RawFileList = docker exec -i $ContainerName $SqlCmdPath -S localhost -U sa -P $script:MSSQL_SA_PASSWORD -C -h-1 -W -Q $DiscoveryQuery

    $DataNames = Get-LogicalNames "D" $RawFileList
    $LogNames  = Get-LogicalNames "L" $RawFileList

    if (-not $DataNames -or -not $LogNames) {
        Write-Error "Error: Could not retrieve logical names from $BakFilename"
        return $false
    }

    # Build MOVE statements
    $MoveStatements = @()
    foreach ($Name in $DataNames) { $MoveStatements += "MOVE '$Name' TO '$MssqlDataDir/${DbName}_$Name.mdf'" }
    foreach ($Name in $LogNames)  { $MoveStatements += "MOVE '$Name' TO '$MssqlDataDir/${DbName}_$Name.ldf'" }
    
    $SqlMove = $MoveStatements -join ", "
    $RestoreQuery = "RESTORE DATABASE [$DbName] FROM DISK = '$BakPath' WITH $SqlMove, REPLACE, STATS = 5;"

    Write-Host "--- Executing Restore with Multi-File Support ---"
    docker exec -i $ContainerName $SqlCmdPath -S localhost -U sa -P $script:MSSQL_SA_PASSWORD -C -Q $RestoreQuery
}

# Function: Deploy-SampleDb
# Purpose: Master orchestrator
function Deploy-SampleDb($Url, $DbName) {
    $BakFilename = Split-Path $Url -Leaf
    $LocalPath = Join-Path $PSScriptRoot $BakFilename

    Write-Host "***************************************************"
    Write-Host "STARTING DEPLOYMENT FOR: $DbName"
    Write-Host "***************************************************"

    # Simplified workflow using PowerShell's native ErrorActionPreference
    try {
        # Check/Download logic
        if (-not (Test-Path $LocalPath)) {
            (New-Object System.Net.WebClient).DownloadFile($Url, $LocalPath)
        }

        # Transfer (Same Docker commands)
        docker exec -u root $ContainerName mkdir -p $MssqlBackupDir
        docker cp "$LocalPath" "$($ContainerName):$MssqlBackupDir/$BakFilename"
        docker exec -u root $ContainerName chown mssql:root "$MssqlBackupDir/$BakFilename"

        # Short pause to ensure file is ready inside container before we query it
        Start-Sleep -Seconds 2 

        # Database Ops
        Remove-Db $DbName
        Restore-Db $DbName $BakFilename
        
        Write-Host "SUCCESS: $DbName is ready."
        return $true
    }
    catch {
        Write-Error "FAILURE: Deployment failed for $DbName. $_"
        return $false
    }
}