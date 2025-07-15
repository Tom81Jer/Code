# first issue restart for all servers
$computers = @("Server01", "Server02", "Server03")
Restart-Computer -ComputerName $computers -Force

# wait until each machine is truly offline
$offlineConfirmed = @()
while ($offlineConfirmed.Count -lt $computers.Count) {
    foreach ($computer in $computers | Where-Object { $_ -notin $offlineConfirmed }) {
        if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
            $offlineConfirmed += $computer
        }
    }
    Start-Sleep -Seconds 5
}

# Now wait until each comes back online
$pending = $offlineConfirmed.Clone()
while ($pending.Count -gt 0) {
    foreach ($computer in $pending.ToArray()) {
        if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
            Write-Host "$computer : complete" -ForegroundColor Green
            $pending.Remove($computer)
        }
    }
    Start-Sleep -Seconds 5
}
