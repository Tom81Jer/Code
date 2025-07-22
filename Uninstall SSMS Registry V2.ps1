Invoke-Command -ComputerName "RemotePC" -ScriptBlock {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    $ssms = "Microsoft SQL Server Management Studio"

    foreach ($path in $paths) {
        Get-ChildItem $path | ForEach-Object {
            $props = Get-ItemProperty $_.PSPath
            if ($props.DisplayName -like "$ssms*") {
                $uninstallCmd = $props.UninstallString
                if ($props.UninstallString) {                    
                    Start-Process $($props.UninstallString)  -Wait -Verb RunAs
                }
            }
        }
    }
}
