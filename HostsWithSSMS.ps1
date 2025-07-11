# Define your list of hostnames
$hosts = @("Host1", "Host2", "Host3")  # Replace with actual hostnames

# SSMS identifiers typically contain "SQL Server Management Studio"
$ssmsPattern = "SQL Server Management Studio"

# Stores results
$ssmsFoundHosts = @()

foreach ($host in $hosts) {
    try {
        $softwareList = Get-WmiObject -Class Win32_Product -ComputerName $host -ErrorAction Stop |
            Where-Object { $_.Name -like "*$ssmsPattern*" }

        if ($softwareList) {
            $ssmsFoundHosts += $host
            Write-Host "✔ SSMS found on $host"
        } else {
            Write-Host "✖ SSMS not found on $host"
        }
    } catch {
        Write-Host "⚠ Error connecting to $host: $_"
    }
}

# Output hosts with SSMS installed
$ssmsFoundHosts
