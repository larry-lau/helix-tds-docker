param(
	[string]$env,
    [ValidateSet('SITE','CD','CM', 'ID')]
    [string] $role ='SITE' #CD, CM, ID, SITE
)

if ($env)
{
    $envFile = "$PSScriptRoot\$env\.env"
} 

if (Test-Path .\.env)
{
    $envFile = ".\.env"
}

$hash = @{}
$lineCount = 1 
Get-Content $envFile | %{
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
