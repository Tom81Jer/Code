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