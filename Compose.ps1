param(
	[string]$env = 'xp1',
	[string]$COMMAND = "up -d"
)

"docker-compose -f .\$env\docker-compose.yml -f .\$env\docker-compose.override.yml $COMMAND"
docker-compose -f .\$env\docker-compose.yml -f .\$env\docker-compose.override.yml $COMMAND