$computers = @("Server1", "Server2", "Server3")
$regex = ".*SQL Server.*Management Studio.*"

foreach ($computer in $computers) {
    Invoke-Command -ComputerName $computer -ScriptBlock {
        $paths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        foreach ($path in $paths) {
            $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -match $using:regex }
            Write-Host "Processing $env:COMPUTERNAME ..."
            foreach ($app in $apps) {
                if ($app.UninstallString) {
                    Write-Host "    Uninstalling: $($app.DisplayName)"
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$($app.UninstallString)`"" -Wait
                } else {
                    Write-Warning "    No uninstall string found for $($app.DisplayName)"
                }
            }
        }
    }
}
