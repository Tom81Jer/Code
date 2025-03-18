# example: 

param (
    [string]$source_publisher,       # The source publisher SQL server
    [string]$target_publisher,       # The target publisher SQL server
    [string]$target_distributor,     # The target distributor SQL server
    [string]$snapshot_folder,        # Folder path for snapshot storage
    [string]$output_folder           # Folder path to store output scripts
)

# Function to retrieve a list of replication users from the publisher
function Get-ReplicationUsers {
    param (
        [string]$publisher
    )
    
    $connectionString = "Server=$publisher;Integrated Security=True;"

    # SQL query to get users in the Publication Access List (PAL)
    $query = @"
    SELECT login FROM sys.syslogins
    WHERE name IN (
        SELECT login
        FROM msdb.dbo.sysreplicationaliases
        WHERE publisher = '$publisher'
    );
    "@

    # Execute the query and return results
    $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionString
    return $result
}

# Retrieve replication users from the publisher
$replicationUsers = Get-ReplicationUsers -publisher $source_publisher

# Assuming you retrieve a valid user (just using the first one found for simplicity)
if ($replicationUsers.Count -gt 0) {
    $subscription_user = $replicationUsers[0].login
    Write-Host "Using subscription user: $subscription_user"
} else {
    Write-Host "No replication users found on the publisher. Please ensure the PAL is populated."
    exit
}

# Helper function to write the SQL script to the output file
function Write-SqlScript {
    param (
        [string]$script,
        [string]$filePath
    )

    Set-Content -Path $filePath -Value $script
    Write-Host "Generated SQL script: $filePath"
}

# Step 1: Get list of publications on the source publisher server
$sourceConnectionString = "Server=$source_publisher;Integrated Security=True;"

# Connect to source server and get the list of publications and articles
$query = @"
SELECT
    p.name AS PublicationName,
    a.name AS ArticleName,
    s.name AS SubscriberName
FROM
    sys.publications p
JOIN
    sys.publication_articles a ON p.publication_id = a.publication_id
JOIN
    sys.repl_articles r ON a.article_id = r.article_id
JOIN
    sys.subscribers s ON s.publisher_id = p.publisher_id
WHERE
    p.publisher_id = (SELECT publisher_id FROM sys.sysservers WHERE name = '$source_publisher');
"@

# Execute query using Invoke-Sqlcmd to get the publications and articles
$publicationData = Invoke-Sqlcmd -Query $query -ConnectionString $sourceConnectionString

# Step 2: Prepare the full script to be written for the publisher
$fullPublisherScript = ""

# Prepare individual scripts for each subscriber
$subscriberScripts = @{}

foreach ($publication in $publicationData) {
    $publicationName = $publication.PublicationName
    $articleName = $publication.ArticleName
    $subscriberName = $publication.SubscriberName

    # Step 2.1: Generate SQL script for creating the publication on the target publisher
    $createPublicationScript = @"
USE [master];
EXEC sp_addpublication 
    @publication = '$publicationName',
    @publisher = '$target_publisher',
    @publication_type = 1;  -- Transactional publication
"@

    # Step 2.2: Generate SQL script for adding the distributor
    $createDistributorScript = @"
USE [master];
EXEC sp_adddistributor 
    @distributor = '$target_distributor';
"@

    # Step 2.3: Generate SQL script for adding articles to the publication
    $addArticleScript = @"
USE [$publicationName];
EXEC sp_addarticle
    @publication = '$publicationName',
    @article = '$articleName',
    @source_object = '$articleName',
    @type = 1; -- For transactional replication
"@

    # Step 2.4: Generate SQL script for creating pull subscription (to be added for each subscriber)
    $addPullSubscriptionScript = @"
USE [master];
EXEC sp_addsubscription
    @publication = '$publicationName',
    @subscriber = '$subscriberName',
    @subscription_type = 'Pull', -- Pull subscription
    @sync_type = 'Replication Support Only'; -- First sync, create pull subscription
"@

    # Step 2.5: Generate SQL script for adding the pull subscription (sp_addpullsubscription)
    $addPullSubscriptionSql = @"
USE [master];
EXEC sp_addpullsubscription
    @publication = '$publicationName',
    @subscriber = '$subscriberName';
"@

    # Step 2.6: Generate snapshot script
    $snapshotScript = @"
USE [$publicationName];
EXEC sp_startpublication_snapshot
    @publication = '$publicationName',
    @publisher = '$target_publisher',
    @snapshot_folder = '$snapshot_folder';
"@

    # Step 3: Generate SQL script to grant PAL permissions to the subscription user
    $grantPALScript = @"
USE [master];
EXEC sp_grant_publication_access
    @publication = '$publicationName',
    @login = '$subscription_user';
"@

    # Add all the publisher-related scripts to the fullPublisherScript variable
    $fullPublisherScript += $createPublicationScript + "`n" + $createDistributorScript + "`n" +
                            $addArticleScript + "`n" + $snapshotScript + "`n" +
                            $grantPALScript + "`n"

    # Prepare the script for the subscriber
    if (-not $subscriberScripts.ContainsKey($subscriberName)) {
        $subscriberScripts[$subscriberName] = ""
    }

    # Append the pull subscription related commands for this subscriber
    $subscriberScripts[$subscriberName] += $addPullSubscriptionScript + "`n" + $addPullSubscriptionSql + "`n"
}

# Step 4: Write the full SQL script for the publisher
$publisherFolder = Join-Path -Path $output_folder -ChildPath $source_publisher
if (-not (Test-Path $publisherFolder)) {
    New-Item -Path $publisherFolder -ItemType Directory | Out-Null
}

$publisherScriptFilePath = Join-Path -Path $publisherFolder -ChildPath "$source_publisher_Replication_Script.sql"
Write-SqlScript -script $fullPublisherScript -filePath $publisherScriptFilePath

# Step 5: Write individual SQL scripts for each subscriber
foreach ($subscriberName in $subscriberScripts.Keys) {
    $subscriberScript = $subscriberScripts[$subscriberName]

    # Create a subfolder for the subscriber inside the source server folder
    $subscriberFolder = Join-Path -Path $publisherFolder -ChildPath $subscriberName
    if (-not (Test-Path $subscriberFolder)) {
        New-Item -Path $subscriberFolder -ItemType Directory | Out-Null
    }

    # Create the subscriber's script file
    $subscriberScriptFilePath = Join-Path -Path $subscriberFolder -ChildPath "$subscriberName_Replication_Script.sql"
    Write-SqlScript -script $subscriberScript -filePath $subscriberScriptFilePath
}

Write-Host "SQL replication script for publisher and individual subscriber scripts have been generated successfully."
