[CmdletBinding()]
Param (
    [string]
    $LicenseXmlPath = ".\install-assets",
    [string]
    $ProjectPrefix = "helix",    
    [string]
    $Env = 'xm1',
    # We do not need to use [SecureString] here since the value will be stored unencrypted in .env,
    # and used only for transient local example environment.
    [string]
    $SitecoreAdminPassword = "b"
)

$ErrorActionPreference = "Stop";

if (-not (Test-Path $LicenseXmlPath)) {
    throw "Did not find $LicenseXmlPath"
}
if (Test-Path $LicenseXmlPath -PathType Leaf) {
    # We want the folder that it's in for mounting
    $LicenseXmlPath = (Get-Item $LicenseXmlPath).Directory.FullName
}

Write-Host "Copying sample .env..." -ForegroundColor Green
Copy-Item .env-sample -Destination .env

$HostName = "$ProjectPrefix-$Env"

# Check for Sitecore Gallery
Import-Module PowerShellGet
$SitecoreGallery = Get-PSRepository | Where-Object { $_.SourceLocation -eq "https://sitecore.myget.org/F/sc-powershell/api/v2" }
if (-not $SitecoreGallery) {
    Write-Host "Adding Sitecore PowerShell Gallery..." -ForegroundColor Green 
    Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2 -InstallationPolicy Trusted
    $SitecoreGallery = Get-PSRepository -Name SitecoreGallery
}
# Install and Import SitecoreDockerTools 
$dockerToolsVersion = "10.1.4"
Remove-Module SitecoreDockerTools -ErrorAction SilentlyContinue
if (-not (Get-InstalledModule -Name SitecoreDockerTools -RequiredVersion $dockerToolsVersion  -ErrorAction SilentlyContinue)) {
    Write-Host "Installing SitecoreDockerTools..." -ForegroundColor Green
    Install-Module SitecoreDockerTools -RequiredVersion $dockerToolsVersion  -Scope CurrentUser -Repository $SitecoreGallery.Name
}
Write-Host "Importing SitecoreDockerTools..." -ForegroundColor Green
Import-Module SitecoreDockerTools -RequiredVersion $dockerToolsVersion

###############################
# Populate the environment file
###############################

Write-Host "Populating required .env file variables..." -ForegroundColor Green

# COMPOSE_PROJECT_NAME
Set-EnvFileVariable "COMPOSE_PROJECT_NAME" -Value $HostName

# HOST_LICENSE_FOLDER
Set-EnvFileVariable "HOST_LICENSE_FOLDER" -Value $LicenseXmlPath

# CD_HOST
Set-EnvFileVariable "CD_HOST" -Value "cd.$($ProjectPrefix).localhost"

# CM_HOST
Set-EnvFileVariable "CM_HOST" -Value "cm.$($ProjectPrefix).localhost"

# ID_HOST
Set-EnvFileVariable "ID_HOST" -Value "id.$($ProjectPrefix).localhost"

# SITE_HOST
Set-EnvFileVariable "SITE_HOST" -Value "www.$($ProjectPrefix).localhost"

# SITECORE_ADMIN_PASSWORD
Set-EnvFileVariable "SITECORE_ADMIN_PASSWORD" -Value $SitecoreAdminPassword

# SQL_SA_PASSWORD
Set-EnvFileVariable "SQL_SA_PASSWORD" -Value (Get-SitecoreRandomString 12 -DisallowSpecial -EnforceComplexity)

# TELERIK_ENCRYPTION_KEY = random 64-128 chars
Set-EnvFileVariable "TELERIK_ENCRYPTION_KEY" -Value (Get-SitecoreRandomString 128)

# SITECORE_IDSECRET = random 64 chars
Set-EnvFileVariable "SITECORE_IDSECRET" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)

# SITECORE_ID_CERTIFICATE
$idCertPassword = Get-SitecoreRandomString 12 -DisallowSpecial
Set-EnvFileVariable "SITECORE_ID_CERTIFICATE" -Value (Get-SitecoreCertificateAsBase64String -DnsName "localhost" -Password (ConvertTo-SecureString -String $idCertPassword -Force -AsPlainText))

# SITECORE_ID_CERTIFICATE_PASSWORD
Set-EnvFileVariable "SITECORE_ID_CERTIFICATE_PASSWORD" -Value $idCertPassword

# REPORTING_API_KEY = random 64-128 chars
Set-EnvFileVariable "REPORTING_API_KEY" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)

# MEDIA_REQUEST_PROTECTION_SHARED_SECRET
Set-EnvFileVariable "MEDIA_REQUEST_PROTECTION_SHARED_SECRET" -Value (Get-SitecoreRandomString 64)

Set-EnvFileVariable "SITECORE_ENCRYPTION_KEY" -Value (Get-SitecoreRandomString 64 -DisallowSpecial)

##################################
# Updating environment file
##################################

$envFile = "$Env\.env"
if (Test-Path $envFile)
{
    $existingEnvHash = (Get-Content $envFile -Raw).Replace("\", "\\") | ConvertFrom-StringData
}

$newEnvHash = (Get-Content .env -Raw).Replace("\", "\\") | ConvertFrom-StringData

if ($existingEnvHash)
{
    Write-Host "Merging existing $Env\.env..." -ForegroundColor Green
    $newEnvHash.Clone().Keys | % {
        $key = $_
        if ($existingEnvHash.Contains($key))
        {
            $newEnvHash[$key] = $existingEnvHash[$key]
        } else {
            Write-Host "`tAdding $key..." #-ForegroundColor Yellow
        }
        Set-EnvFileVariable -Path "$Env\.env" -Variable $key -Value $newEnvHash[$key]
    }
} else {
    Write-Host "Copy .env to $env..." -ForegroundColor Green
    Move-Item .env -Destination "$Env\.env" #-Force
}


##################################
# Configure TLS/HTTPS certificates
##################################

Push-Location docker\traefik\certs
try {
    $mkcert = ".\mkcert.exe"
    if ($null -ne (Get-Command mkcert.exe -ErrorAction SilentlyContinue)) {
        # mkcert installed in PATH
        $mkcert = "mkcert"
    } elseif (-not (Test-Path $mkcert)) {
        Write-Host "Downloading and installing mkcert certificate tool..." -ForegroundColor Green 
        Invoke-WebRequest "https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1-windows-amd64.exe" -UseBasicParsing -OutFile mkcert.exe
        if ((Get-FileHash mkcert.exe).Hash -ne "1BE92F598145F61CA67DD9F5C687DFEC17953548D013715FF54067B34D7C3246") {
            Remove-Item mkcert.exe -Force
            throw "Invalid mkcert.exe file"
        }
    }
    Write-Host "Generating Traefik TLS certificate..." -ForegroundColor Green
    & $mkcert -install
    & $mkcert "*.$($ProjectPrefix).localhost"
}
catch {
    Write-Host "An error occurred while attempting to generate TLS certificate: $_" -ForegroundColor Red
}
finally {
    Pop-Location
}

Push-Location docker\traefik\config\dynamic
try {
    $sel = Select-String -Path .\certs_config.yaml -Pattern $ProjectPrefix
    if (!$sel)
    {
        Add-Content -Path certs_config.yaml -Value "`n    - certFile: C:\etc\traefik\certs\_wildcard.$ProjectPrefix.localhost.pem"
        Add-Content -Path certs_config.yaml -Value "      keyFile: C:\etc\traefik\certs\_wildcard.$ProjectPrefix.localhost-key.pem"    
    }
}
catch {
    Write-Host "An error occurred while attempting to updating certs_config.yaml: $_" -ForegroundColor Red
}
finally {
    Pop-Location
}

################################
# Add Windows hosts file entries
################################

Write-Host "Adding Windows hosts file entries..." -ForegroundColor Green

Add-HostsEntry "cd.$($ProjectPrefix).localhost"
Add-HostsEntry "cm.$($ProjectPrefix).localhost"
Add-HostsEntry "id.$($ProjectPrefix).localhost"
Add-HostsEntry "www.$($ProjectPrefix).localhost"

Write-Host "Done!" -ForegroundColor Green

