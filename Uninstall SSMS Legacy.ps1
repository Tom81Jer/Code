Invoke-Command -ComputerName $server -ScriptBlock {
    $ssmsName = "SQL Server Management Studio"
    $apps = wmic product get name
    foreach ($app in $apps) {
        if ($app -like "*$ssmsName*") {
            wmic product where "name like '%$ssmsName%'" call uninstall /nointeractive
        }
    }
}

