param (
    [string]$source_publisher,       # The source publisher SQL server
    [string]$target_publisher,       # The target publisher SQL server
    [string]$target_distributor,     # The target distributor SQL server
    [string]$snapshot_folder,        # Folder path for snapshot storage
    [string]$output_folder,          # Folder path to store output scripts
    [string]$subscription_user       # The SQL Server login to grant PAL permissions
)

# Helper function to write the SQL script to the output file
function Write-SqlScript {
    param (
        [string]$script,
        [string]$scriptName,
        [string]$sourceServer
    )

    $serverFolder = Join-Path -Path $output_folder -ChildPath $sourceServer
    if (-not
