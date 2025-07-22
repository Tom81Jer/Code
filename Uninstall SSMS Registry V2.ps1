Invoke-Command -ComputerName "RemotePC" -ScriptBlock {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    $filter = "Microsoft SQL Server Management Studio"

    foreach ($path in $paths) {
        Get-ChildItem $path | ForEach-Object {
            $props = Get-ItemProperty $_.PSPath
            if ($props.DisplayName -like "*$filter*") {
                $uninstallCmd = $props.UninstallString
                if ($uninstallCmd) {
                    $exe = $uninstallCmd -replace "/uninstall", ""
                    Start-Process $exe -ArgumentList "/uninstall /quiet /norestart" -Wait -Verb RunAs
                }
            }
        }
    }
}
