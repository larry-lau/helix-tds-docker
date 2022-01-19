param(
    [string]
    $Env = 'xm1'
)

$ErrorActionPreference = "Stop";

Import-Module SitecoreDockerTools
[Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("System.Linq") | Out-Null

$envFile = "$Env\.env"

if (Test-Path $envFile)
{
    
} else {
    
    throw "$Env\.env file not found $((get-item .).FullName) Please run docker-init.ps1 first"
}

$variableHash = @{}
try {
    $variableHash = (Get-Content $envFile -Raw).Replace("\", "\\") | ConvertFrom-StringData 
}
catch {
    throw "Error processing $File"
}

function Encrypt-Text($plainTextBytes, $keyBytes)
{
    $rijndael = [System.Security.Cryptography.Rijndael]::Create()
    
    #$rijndael.Key = [System.Linq.Enumerable]::Take($keyBytes, 32)
    #$rijndael.IV = [System.Linq.Enumerable]::TakeLast($keyBytes, 16) # Windows PowerShell doesn't support TakeLast

    $rBytes = [byte[]]::new(32)    
    [Array]::Copy($keyBytes, 0, $rBytes, 0, $rBytes.Length)
    $rijndael.Key = $rBytes

    $ivBytes = [byte[]]::new(16)    
    [Array]::Copy($keyBytes, 32, $ivBytes, 0, $ivBytes.Length)
    $rijndael.IV = $ivBytes

    $encryptor = $rijndael.CreateEncryptor($rijndael.Key, $rijndael.IV)

    [System.IO.Stream]$ms = new-Object IO.MemoryStream
    $cs = new-Object System.Security.Cryptography.CryptoStream $ms,$encryptor,"Write"	
    $cs.Write($plainTextBytes, 0, $plainTextBytes.Length);
    $cs.FlushFinalBlock();

    [byte[]]$cipherTextBytes = $ms.ToArray();  

    return $cipherTextBytes
}

function Generate-EncryptionKey()
{
    $rijndael = [System.Security.Cryptography.Rijndael]::Create()
    $rBytes = [byte[]]::new(48)
    [Array]::Copy($rijndael.Key, 0, $rBytes, 0, $rijndael.Key.Length)
    [Array]::Copy($rijndael.IV, 0, $rBytes, 32, $rijndael.IV.Length)
    return [Convert]::ToBase64String($rBytes)
}

$encryptionKeyInEnv = $variableHash['SITECORE_ENCRYPTION_KEY']

if (!$encryptionKeyInEnv)
{
    "SITECORE_ENCRYPTION_KEY not set. Generating a new key"
    $encryptionKeyInEnv = Generate-EncryptionKey

    "SITECORE_ENCRYPTION_KEY is set to $encryptionKeyInEnv"
    Set-EnvFileVariable -Path "$Env\.env" -Variable SITECORE_ENCRYPTION_KEY -Value $encryptionKeyInEnv
}

$keyBytes = [Convert]::FromBase64String($encryptionKeyInEnv)
if ($keyBytes.Length -ne 48)
{
    throw "Invalid Sitecore Encryption Key"
}

$envVariablesToEncrypt = @(
    'COVEO_PASSWORD'
    ,'COVEO_API_KEY'
    ,'COVEO_SEARCH_API_KEY')

$envVariablesToEncrypt | % {
    $varName = $_
    $encryptedVarName = "$($varName)_ENCRYPTED"
    if ($variableHash[$varName])
    {
        $textBytes = [Text.Encoding]::UTF8.GetBytes($variableHash[$varName])
        $encryptedBytes = Encrypt-Text -plainTextBytes $textBytes -keyBytes $keyBytes
        $encryptedText = [Convert]::ToBase64String($encryptedBytes)
        "Setting $encryptedVarName to $encryptedText"
        Set-EnvFileVariable -Path "$Env\.env" -Variable $encryptedVarName -Value $encryptedText
    } else {
        Set-EnvFileVariable -Path "$Env\.env" -Variable $encryptedVarName -Value ''
    }
}