param(
    [Switch]$Complete
)

$ErrorActionPreference = 'Stop'

if ($Complete)
{
    # rebuilding everything
    docker-compose down
    docker-compose build --memory=10g --force-rm 
} 
else 
{
    # Only rebuilding cd and cm
    docker-compose stop cd cm mssql
    docker-compose rm -f    
    docker-compose build --memory=5g --force-rm solution cd cm
}
docker-compose up -d 