# Scripts for Loading Data to Microsoft SQL Server

This folder contains the automation logic for managing and deploying sample databases to a SQL Server Docker container.

### Scripts Overview

* **`utility.ps1`**: A library of functions for downloading backups, handling multi-file logical name mapping, and executing SQL commands inside the container.
* **`usage.ps1`**: The entry-point script that iterates through a list of databases (AdventureWorks, WideWorldImporters, etc.) and triggers the deployment process.

### Requirements

* **Docker**: A running container named `infra_mssql`.
* **PowerShell**: Version 7+ (`pwsh`) installed on your host machine.
* **Configuration**: A `.env` file hosting the password.

### How to Run

Execute the following command from the scripts directory:

```powershell
# chang to app folder
cd apps\infra_mssql
# run the script
.\scripts\usage.ps1
```

> **Note:** The scripts are designed to find the `.env` file in the **parent directory** automatically using relative pathing.

