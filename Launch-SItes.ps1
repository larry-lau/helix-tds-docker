param(
	[string]$env = "xm1",
    $role ='SITE' #CD, CM, ID, SITE
)

$hash = @{}
$lineCount = 1 
Get-Content .\$env\.env | %{
    if ($_)
    {
        $line=$_.Trim()
        if (!$line.StartsWith('#'))
        {
            $envVarName = $line.Substring(0, $line.IndexOf("="))
            $envVarValue = $line.Substring($line.IndexOf("=")+1, $line.Length - $line.IndexOf("=")-1)
            $hash.Add($envVarName.Trim(), $envVarValue.Trim())    
        }
    }
    $lineCount++
}

$roleHostKey = "$($role)_HOST"
$roleHost = $hash[$roleHostKey]

if ($roleHost)
{
    $URL = "https://$roleHost/"
    Write-host "Launching $URL..."
    Start-Process $URL
} else {
    Write-host "$roleHostKey is not defined"
}
