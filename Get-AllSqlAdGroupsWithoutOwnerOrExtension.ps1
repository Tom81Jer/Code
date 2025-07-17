# This script returns all the SQL AD groups with either or both properties are not set: ManagedBy and ExtensionAttribute1

Import-Module ActiveDirectory

$pattern = '^SQL_[A-Za-z]0\d{3}[A-Za-z0-9]{2,}_[A-Za-z0-9]+$'

# Step 1: Get all security groups with names matching the pattern
$namedGroups = Get-ADGroup -Filter { GroupCategory -eq 'Security' } | Where-Object {
    $_.Name -match $pattern
}

# Step 2: Retrieve extended properties only for matching groups
$filteredGroups = foreach ($group in $namedGroups) {
    $fullGroup = Get-ADGroup -Identity $group.DistinguishedName -Properties ManagedBy, ExtensionAttribute1
    if (-not $fullGroup.ManagedBy -or -not $fullGroup.ExtensionAttribute1) {
        $fullGroup
    }
}

# Output results
$filteredGroups | Select-Object Name, ManagedBy, ExtensionAttribute1

