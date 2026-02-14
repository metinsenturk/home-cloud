# ==============================================================================
# SQL SERVER SAMPLE DATABASE DEPLOYMENT TOOL (POWERSHELL ENTRY POINT)
# ==============================================================================
# Description:
#   Orchestrates the deployment of specific datasets using the 'utility.ps1' 
#   library.
#
# Execution:
#   .\usage.ps1
# ==============================================================================

# 1. Import the utility functions
# This ensures utility.ps1 is in the same directory
$UtilityPath = Join-Path $PSScriptRoot "utility.ps1"
if (Test-Path $UtilityPath) {
    . $UtilityPath
} else {
    Write-Error "Required library 'utility.ps1' not found."
    exit
}

# 2. Load the environment configuration
if (-not (Load-Config)) {
    Write-Error "Configuration failed. Check your .env file."
    exit
}

# 3. Define Databases to Deploy
# Format: "DatabaseName" = "URL"
$Databases = @{
    "AdventureWorks"      = "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak"
    "AdventureWorksDW"    = "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksDW2022.bak"
    "WideWorldImporters"  = "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bak"
}

Write-Host "Starting bulk deployment of $($Databases.Count) databases..."

# 4. Loop through the Hashtable
foreach ($DbName in $Databases.Keys) {
    $Url = $Databases[$DbName]
    
    # Run the master deployment orchestrator
    # Note: Remove-Db is now called internally by Deploy-SampleDb in the PS version
    if (-not (Deploy-SampleDb -Url $Url -DbName $DbName)) {
        Write-Warning "Skipping to next database due to failure in $DbName."
    }
}

Write-Host "==================================================="
Write-Host "ALL DEPLOYMENTS COMPLETED"
Write-Host "==================================================="