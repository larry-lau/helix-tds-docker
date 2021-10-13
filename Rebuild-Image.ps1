param(
	[string]$env,
    [ValidateSet('SITE','CD','CM', 'ID')]
    [string] $role ='CM' #CD, CM, ID, SITE
)

if ($env)
{
    $envFile = "$PSScriptRoot\$env\.env"
} 

if (Test-Path .\.env)
{
    $envFile = ".\.env"
}

docker-compose stop $role
docker-compose rm $role -f
docker-compose build solution $role
#docker-compose build $role
docker-compose up -d 