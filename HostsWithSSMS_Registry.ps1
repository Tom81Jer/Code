$computers = @("Server1", "Server2", "Server3")
$regex = ".*SQL Server.*Management Studio.*"

foreach ($computer in $computers) {
    Invoke-Command -ComputerName $computer -ScriptBlock {
        $paths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        foreach ($path in $paths) {
            Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -match $using:regex } |
                Select-Object @{Name="ComputerName";Expression={$env:COMPUTERNAME}}, DisplayName, DisplayVersion
        }
    }
}
