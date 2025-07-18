$computers = @("Server1", "Server2", "Server3")
$regex = ".*SQL Server.*Management Studio.*"
$serversWithMatches = @()

foreach ($computer in $computers) {
    Write-Host "`nScanning $computer..." -ForegroundColor Cyan

    $matches = Invoke-Command -ComputerName $computer -ScriptBlock {
        $paths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        $found = @()
        foreach ($path in $paths) {
            $found += Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -match ".*SQL Server.*Management Studio.*" } |
                Select-Object DisplayName, DisplayVersion
        }
        return $found
    }

    if ($matches.Count -gt 0) {
        $serversWithMatches += $computer
        foreach ($match in $matches) {
            Write-Host ("    {0}  {1}" -f $match.DisplayName, $match.DisplayVersion)
        }
    }
}

# Final summary
if ($serversWithMatches.Count -gt 0) {
    Write-Host "`nServers with matching software: $($serversWithMatches -join ', ')" -ForegroundColor Green
} else {
    Write-Host "`nNo matching software found on any server." -ForegroundColor Yellow
}
