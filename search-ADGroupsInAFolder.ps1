# Define the OU path to search for groups
$ouPath = "OU=Audited Sql Groups,OU=Sql Groups,DC=yourdomain,DC=com"  # Replace with your domain's distinguished name

# Search for AD security groups starting with "SQL_" (case-insensitive)
$groups = Get-ADGroup -Filter 'Name -like "SQL_*" -and GroupCategory -eq "Security"' -SearchBase $ouPath -Properties ExtensionAttribute1

# Check each group
foreach ($group in $groups) {
    Write-Host "Checking $($group.Name)..."
    # Check if ExtensionAttribute1 is not "covered" (case-insensitive comparison)
    if ($group.ExtensionAttribute1 -ne $null -and $group.ExtensionAttribute1.ToLower() -ne "covered") {
        Write-Host "  Group '$($group.Name)' has ExtensionAttribute1 set to '$($group.ExtensionAttribute1)' (not 'covered')."
    } elseif ($group.ExtensionAttribute1 -eq $null) {
        Write-Host "  Group '$($group.Name)' has no value set for ExtensionAttribute1."
    }
}
