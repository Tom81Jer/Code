## Find SQL AD groups where either property is not set.

# Import the Active Directory module
Import-Module ActiveDirectory

# Define the search pattern
$NamePattern = "SQL*"

# Fetch groups that start with 'SQL'
$Groups = Get-ADGroup -Filter { Name -like $NamePattern } `
    -Properties managedBy, extensionAttribute1, GroupCategory

# Filter only security-enabled groups where one or both properties are missing
$IncompleteGroups = $Groups | Where-Object {
    $_.GroupCategory -eq 'Security' -and 
    (
        -not $_.managedBy -or 
        -not $_.extensionAttribute1
    )
}

# Output results
$IncompleteGroups | Select-Object  Name, extensionAttribute1,  @{Name = "ManagerCN"; Expression = {
        if ($_.managedBy -match "CN=([^,]+)") { $matches[1] } else { "Not Set" }
    }}
=======================================================
# Import Active Directory module
Import-Module ActiveDirectory

# Parameters
$SearchPattern = "*Finance*"              # Replace with your desired name pattern
$ManagerSamAccountName = "jdoe"          # Replace with sAMAccountName of the manager

# Resolve the manager's distinguished name
$ManagerAccount = Get-ADUser -Identity $ManagerSamAccountName -Properties DistinguishedName
if (-not $ManagerAccount) {
    Write-Host "Manager account '$ManagerSamAccountName' not found." -ForegroundColor Red
    return
}
$ManagerDN = $ManagerAccount.DistinguishedName

# 1. Get security-enabled groups with names matching the pattern
$Groups = Get-ADGroup -Filter {
    Name -like $SearchPattern -and GroupScope -ne "Distribution"
} -Properties GroupCategory, SamAccountName

# 2. Filter for only security-enabled groups (GroupCategory = "Security")
$SecurityGroups = $Groups | Where-Object { $_.GroupCategory -eq "Security" }

# 3. Update attributes for each group
foreach ($Group in $SecurityGroups) {
    try {
        Set-ADGroup -Identity $Group.DistinguishedName `
                    -Replace @{
                        managedBy = $ManagerDN
                        extensionAttribute1 = "Standard"
                    }
        Write-Host "Updated group $($Group.SamAccountName) successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error updating $($Group.SamAccountName): $_" -ForegroundColor Yellow
    }
}
