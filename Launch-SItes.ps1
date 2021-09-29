param(
	[string]$env
)

$hash = @{}
$lineCount = 1 
Get-Content .\.env | %{
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

$SITE_HOST = $hash['SITE_HOST']

Start-Process "https://$SITE_HOST/"

