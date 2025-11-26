function Get-LocalAdminViolations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [string[]]$LocalAdmins   # allowed principals for THIS server
    )

    # Result skeleton – ensures a consistent shape
    $result = [PSCustomObject]@{
        ComputerName = $ComputerName
        Success      = $false
        ErrorMessage = $null
        Violations   = @()   # will become an array of violation objects
    }

    # Built-in accounts that are not security threats
    $benignPatterns = @(
        'BUILTIN\Administrators'
        'BUILTIN\Users'
        'NT AUTHORITY\SYSTEM'
        'NT AUTHORITY\LOCAL SERVICE'
        'NT AUTHORITY\NETWORK SERVICE'
        'NT SERVICE\*'
        'Everyone'
        'NT AUTHORITY\Authenticated Users'
    )

    try {
        $members = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Get-LocalGroupMember -Group 'Administrators' |
                Select-Object Name, ObjectClass, SID
        }

        $result.Success = $true
    }
    catch {
        # Capture the error but keep the shape the same
        $result.ErrorMessage = $_.Exception.Message
        return $result
    }

    $violations = New-Object System.Collections.Generic.List[object]

    foreach ($m in $members) {
        $principal = $m.Name
        if ([string]::IsNullOrWhiteSpace($principal)) {
            continue
        }

        # Ignore benign built-ins
        $isBenign = $false
        foreach ($pattern in $benignPatterns) {
            if ($principal -like $pattern) {
                $isBenign = $true
                break
            }
        }
        if ($isBenign) { continue }

        # Allowed? (case-insensitive compare)
        if ($LocalAdmins -contains $principal) { continue }

        # Not benign and not allowed => violation
        $violations.Add(
            [PSCustomObject]@{
                ServerName = $ComputerName
                Principal  = $principal
                Type       = $m.ObjectClass  # 'User' or 'Group'
                SID        = $m.SID.Value
            }
        ) | Out-Null
    }

    # Always assign an array (even if empty)
    $result.Violations = $violations.ToArray()

    return $result
}
