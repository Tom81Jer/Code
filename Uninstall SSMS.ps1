# Define list of remote servers
$servers = @("Server01", "Server02", "Server03")

foreach ($server in $servers) {
    Write-Host "Processing $server..." -ForegroundColor Cyan

    Invoke-Command -ComputerName $server -ScriptBlock {
        # Get list of installed programs
        $installed = Get-WmiObject -Class Win32_Product | Where-Object {
            $_.Name -like "*Microsoft SQL Server Management Studio*"
        }

        if ($installed) {
            foreach ($app in $installed) {
                Write-Host "Uninstalling $($app.Name) on $env:COMPUTERNAME..." -ForegroundColor Yellow
                $app.Uninstall() | Out-Null
                Write-Host "Uninstallation complete." -ForegroundColor Green
            }
        } else {
            Write-Host "SSMS not found on $env:COMPUTERNAME." -ForegroundColor Red
        }
    } 
}

# List of target computers
$computers = @("Server01", "Server02", "Server03")

# Hashtable to store job references
$jobs = @{}

foreach ($computer in $computers) {
    Write-Host "Sending restart command to $computer..." -ForegroundColor Cyan

    # Start a remote job to restart computer
    $jobs[$computer] = Invoke-Command -ComputerName $computer -ScriptBlock {
        try {
            Restart-Computer -Force -Confirm:$false
            "Success"
        } catch {
            "Failure: $($_.Exception.Message)"
        }
    } -AsJob
}

# Wait for jobs to complete
$jobs.Values | Wait-Job

# Collect and display results
foreach ($computer in $computers) {
    $job = $jobs[$computer]
    $result = Receive-Job -Job $job
    if ($result -eq "Success") {
        Write-Host "$computer restarted successfully." -ForegroundColor Green
    } else {
        Write-Host "$computer restart failed: $result" -ForegroundColor Red
    }

    # Clean up
    Remove-Job -Job $job
}
