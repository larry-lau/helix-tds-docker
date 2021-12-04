# escape=`

ARG BASE_IMAGE

FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY Update-EncriptionKeys.ps1 C:\Update-EncriptionKeys.ps1

# Run Coveo Activation Scripts
ENTRYPOINT .\Update-EncriptionKeys.ps1 -SqlServer $env:SQL_SERVER -SqlAdminUser $env:SQL_ADMIN_LOGIN -SqlAdminPassword $env:SQL_ADMIN_PASSWORD -SitecoreEncryptionKey $env:SITECORE_ENCRYPTION_KEY
