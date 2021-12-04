param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]] $roles,
    #[string] $role ='SITE' #CD, CM, ID, SITE
    [switch] $showconfig
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

$roles | % {
    $role = $_
    $roleHostKey = "$($role)_HOST"
    $roleHost = $hash[$roleHostKey]
    
    if ($roleHost)
    {
        $URL = "https://$roleHost"
    
        if ($role.ToLower() -eq "cm")
        {
            $URL = "$URL/sitecore"
        }

        if ($showconfig)
        {
            $URL = "$URL/admin/showconfig.aspx"
        }

        Write-host "Launching $URL..."
        Start-Process $URL
    } else {
        Write-host "$roleHostKey is not defined"
    }    
}