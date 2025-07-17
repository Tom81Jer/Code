function Get-SiblingGroupOwner {
    param (
        [Parameter(Mandatory)]
        [string]$GroupName
    )

    # Define regex pattern with underscore included in Group 1
    $pattern = '^(?i)(SQL_[DSP]_0\d{3}_[A-Z0-9]{2,}_)(R|W|X|O)$'

    # Validate input
    if ($GroupName -notmatch $pattern) {
        Write-Error "Group name does not match the required pattern."
        return $null
    }

    # Extract base name and suffix
    $baseName = $matches[1]  # includes trailing underscore
    $currentSuffix = $matches[2].ToUpper()

    # Define alternate suffixes
    $suffixes = @('R', 'W', 'X', 'O') | Where-Object { $_ -ne $currentSuffix }

    # Search for sibling group with ManagedBy set
    foreach ($suffix in $suffixes) {
        $altGroupName = "$baseName$suffix"
        try {
            $group = Get-ADGroup -Identity $altGroupName -Properties ManagedBy -ErrorAction Stop
            if ($group.ManagedBy) {
                $managerUser = Get-ADUser -Identity $group.ManagedBy -ErrorAction Stop
                Write-Host "Found sibling group: $altGroupName with manager: $($managerUser.sAMAccountName)"
                return $managerUser.sAMAccountName
            }
        } catch {
            continue
        }
    }

    Write-Warning "No sibling group found with ManagedBy set."
    return $null
}