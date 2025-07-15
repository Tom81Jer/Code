# List of computers
$computers = @("Server01", "Server02", "Server03", "LongComputerName001", "ShortPC")

# Header
$header = "{0,-25} {1,-25}" -f "Computer Name", "Last Reboot DateTime"
Write-Host $header -ForegroundColor Yellow
Write-Host ("-" * $header.Length)

# Retrieve and format results
foreach ($computer in $computers) {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $computer -ErrorAction Stop
        $formatted = "{0,-25} {1,-25}" -f $computer, $os.LastBootUpTime
        Write-Host $formatted -ForegroundColor Green
    } catch {
        $errorLine = "{0,-25} {1,-25}" -f $computer, "ERROR: $($_.Exception.Message)"
        Write-Host $errorLine -ForegroundColor Red
    }
}
