param(
    [switch] $setKey
)

if (Test-Path .\.env)
{
    $envFile = ".\.env"
} else {
    
    throw ".env file not found $((get-item .).FullName)"
}

$hash = @{}
try {
    $hash = (Get-Content $envFile -Raw).Replace("\", "\\") | ConvertFrom-StringData 
}
catch {
    throw "Error processing $File"
}

$dbName = "Sitecore.Web"

$encryptionKeyInEnv = $hash['SITECORE_ENCRYPTION_KEY']

if ($encryptionKeyInEnv)
{
    Import-Module SqlServer

    $sa_password = $hash['SQL_SA_PASSWORD']
    
    $encryptionKeyInDB = $(Invoke-Sqlcmd -ServerInstance "localhost,14330" -Database Sitecore.Web -Username sa -Password $sa_password `
                  -Query "SELECT * FROM [Sitecore.Web].[dbo].[Properties] Where ([Key] = 'WEB_ENCRYPTIONKEYS')").Value
    
    "Encryption Key in Env=$encryptionKeyInEnv"
    "Encryption Key in DB =$encryptionKeyInDB"
    
    if ($encryptionKeyInEnv.Equals($encryptionKeyInDB))
    {
        "Encryption key in .env is same as [Sitecore.Web].[dbo].[Properties]" 
    } else {
        "Encryption key in .env is different from [Sitecore.Web].[dbo].[Properties]"         
    }    

    if ($setKey)
    {
        $upsertCmd = @"
        IF EXISTS ( SELECT * FROM [dbo].[Properties] WITH (UPDLOCK) WHERE [Key] = 'WEB_ENCRYPTIONKEYS' ) 
            UPDATE [dbo].[Properties] SET Value = '$encryptionKeyInEnv' WHERE [Key] = 'WEB_ENCRYPTIONKEYS';
        ELSE        
            INSERT [dbo].[Properties] ( [Key], [Value] ) VALUES ( 'WEB_ENCRYPTIONKEYS', '$encryptionKeyInEnv' );
"@
    
        $upsertCmd
        Invoke-Sqlcmd -ServerInstance "localhost,14330" -Database Sitecore.Web -Username sa -Password $sa_password `
            -Query $upsertCmd
    }
}


function Generate-Key()
{
    $rijndael = [System.Security.Cryptography.Rijndael]::Create()
    $rBytes = [byte[]]::new(48)
    [Array]::Copy($rijndael.Key, 0, $rBytes, 0, $rijndael.Key.Length)
    [Array]::Copy($rijndael.IV, 0, $rBytes, 32, $rijndael.IV.Length)
    return [Convert]::ToBase64String($rBytes)
}

