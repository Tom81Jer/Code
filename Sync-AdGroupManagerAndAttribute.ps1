function Sync-AdGroupManagerAndAttribute {
    param (
        [Parameter(Mandatory)]
        [string]$GroupName
    )

    # Get manager from sibling group
    $manager = Get-SiblingGroupOwner -GroupName $GroupName

    if ($manager) {
        # Set ManagedBy on the input group
        Set-AdGroupOwner -ad_group_name $GroupName -ad_login_name $manager

        # Set ExtensionAttribute1 to "Standard"
        Set-AdGroupAttribute -ad_Group_Name $GroupName -ad_attribute "ExtensionAttribute1" -ad_attribute_value "Standard"

        Write-Host "Updated $GroupName with ManagedBy and ExtensionAttribute1."
    } else {
        Write-Warning "No update performed. No sibling group with ManagedBy found."
    }
}
