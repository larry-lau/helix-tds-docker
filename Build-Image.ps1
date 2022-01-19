param(
    [Switch]$Complete,
    [Switch]$Log,
    [Switch]$SkipUp,
    [Parameter(ValueFromRemainingArguments)]
    [string[]] $roles
)

$ErrorActionPreference = 'Stop'

if ($Log)
{	
	Start-Transcript -Path ".\logs\rebuildimage.$(Get-Date -f "yyyyMMdd.HHmmss").log"
}

if ($Complete)
{
    # rebuilding everything
    docker-compose down
    docker-compose build --memory=10g --force-rm
} 
else 
{
    if ($roles)
    {
        $roles | % {
            $role = $_
            Write-Host "docker-compose stop $role"
            & "docker-compose" stop $role
            
            Write-Host "docker-compose rm -f"
            docker-compose rm -f
        
            Write-Host "docker-compose build --memory=10g --force-rm $role"
            docker-compose build --memory=10g --force-rm $role
        }
        
    } else {
        # Only rebuilding key images
        docker-compose stop cd cm 
        docker-compose rm -f
        docker-compose build --memory=10g --force-rm solution cd cm
    }
}

# Clean deploy folders
Get-ChildItem -Path (Join-Path "$PSScriptRoot\docker" "\deploy") -Directory | ForEach-Object {
    $deployPath = $_.FullName

    Get-ChildItem -Path $deployPath -Exclude ".gitkeep" -Recurse | Remove-Item -Force -Recurse -Verbose
}

if (!$SkipUp)
{
    docker-compose up -d
}

if ($Log)
{
	Stop-Transcript
}