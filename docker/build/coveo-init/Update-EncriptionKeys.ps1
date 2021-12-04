[CmdletBinding()]
param (

    [Parameter(Mandatory)]
    [string]$SqlServer,

    [Parameter(Mandatory)]
    [string]$SqlAdminUser,

    [Parameter(Mandatory)]
    [string]$SqlAdminPassword,

    [Parameter(Mandatory)]
    [string]$SitecoreEncryptionKey

)

function Invoke-Sqlcmd {
    param(
        [string]$SqlDatabase,
        [string]$SqlServer,
        [string]$SqlAdminUser,
        [string]$SqlAdminPassword, 
        [string]$Query
    )

    $arguments = " -Q ""$Query"" -S '$SqlServer' "

    if($SqlAdminUser -and $SqlAdminPassword) {
        $arguments += " -U '$SqlAdminUser' -P '$SqlAdminPassword'"
    }
    if($SqlDatabase) {
        $arguments += " -d '$SqlDatabase'"
    }

    Invoke-Expression "sqlcmd $arguments"
}

function Add-SqlAzureConditionWrapper {
    param(
        [string]$SqlQuery
    )
    
    return "DECLARE @serverEdition nvarchar(256) = CONVERT(nvarchar(256),SERVERPROPERTY('edition'));
        IF @serverEdition <> 'SQL Azure'
        BEGIN
            $SqlQuery
        END;
        GO"
}

$databaseName = "Sitecore.Web"
$upsertCmd = @"
IF EXISTS ( SELECT * FROM [dbo].[Properties] WITH (UPDLOCK) WHERE [Key] = 'WEB_ENCRYPTIONKEYS' ) 
    UPDATE [dbo].[Properties] SET Value = '$SitecoreEncryptionKey' WHERE [Key] = 'WEB_ENCRYPTIONKEYS';
ELSE        
    INSERT [dbo].[Properties] ( [Key], [Value] ) VALUES ( 'WEB_ENCRYPTIONKEYS', '$SitecoreEncryptionKey' );
"@

$sqlcmd = Add-SqlAzureConditionWrapper -SqlQuery $upsertCmd

Write-Host "Updating $($databaseName) WEB_ENCRYPTIONKEYS is changed to $SitecoreEncryptionKey"

Invoke-Sqlcmd -SqlServer:$SqlServer -SqlAdminUser:$SqlAdminUser -SqlAdminPassword:$SqlAdminPassword -SqlDatabase "$databaseName" -Query $sqlcmd

if($LASTEXITCODE -ne 0) {
    throw "sqlcmd exited with code $LASTEXITCODE while updating WEB_ENCRYPTIONKEYS of $databaseName"
}
Write-Verbose "$($databaseName) WEB_ENCRYPTIONKEYS is changed to $SitecoreEncryptionKey"
