param(
	[string]$env
)

if ((Test-Path ".env.$env")) {
    Write-Host "Switching to $env..." -ForegroundColor Green 
    Copy-Item ".env.$env" -Destination .env
} else {
    throw "environment file [.env$env] not found"
}