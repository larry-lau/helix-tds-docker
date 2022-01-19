[CmdletBinding()]
Param (
    [string]
    $ProjectPrefix = "helix",    
    [string]
    $CertPassword = "1234"
)

$ErrorActionPreference = "Stop";

##################################
# Configure TLS/HTTPS certificates
##################################
$dockerBuildPath = (Get-Item "docker\build").FullName
$certPath = "docker\traefik\certs"
$certFullPath = (Get-Item $certPath).FullName

$certFilePrefix = "$ProjectPrefix.localhost"
$certFile = "$certFilePrefix.pem"
$keyFile = "$certFilePrefix-key.pem"
$pfxFile = "$certFilePrefix.pfx"
$dnsName = "*.$($ProjectPrefix).localhost"

Push-Location $certPath
try {
    $openssl = ".\openssl.exe"
    if ($null -ne (Get-Command openssl.exe -ErrorAction SilentlyContinue)) {
        # mkcert installed in PATH
        $openssl = "openssl.exe"
    } else {
        throw "openssl.exe not found"
    }
    Write-Host "Generating Traefik TLS certificate..." -ForegroundColor Green
    & $openssl req -x509 -sha256 -nodes -days 3650 -subj "/OU=habaneros/CN=helix" -addext "subjectAltName = DNS:$dnsName" -newkey rsa:2048 -keyout $keyFile -out $certFile
    & $openssl pkcs12 -inkey $keyFile -in $certFile -export -out $pfxFile -password pass:$CertPassword

    Write-Host "Copy PFX $pfxFile to $dockerBuildPath"
    Copy-Item -Path $pfxFile -Destination "$dockerBuildPath\cm\certs"
    Copy-Item -Path $pfxFile -Destination "$dockerBuildPath\cd\certs"
}
catch {
    Write-Host "An error occurred while attempting to generate TLS certificate: $_" -ForegroundColor Red
}
finally {
    Pop-Location
}

$stores = @(
    "Cert:\LocalMachine\My",
    ,"Cert:\LocalMachine\Root"
    ,"Cert:\CurrentUser\My"
    ,"Cert:\CurrentUser\Root")
    
$stores | % {
    $location = $_
    $certs = Get-ChildItem $_ | ? { $_.DnsNameList -contains $dnsName } 
    if ($certs)
    {
        Write-Host "Removing old certificates in $location..." -ForegroundColor Green
        $certs | % {
            Write-Host "Removing "$location\$($_.Thumbprint)"..."
            Remove-Item "$location\$($_.Thumbprint)"
        }
    }    
}

# Import the certifiate in both Root and Personal 
Write-Host "Importing Traefik TLS certificate..." -ForegroundColor Green
$securePassword = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText;
$cert = Import-PfxCertificate -FilePath "$certFullPath\$pfxFile" -CertStoreLocation "Cert:\LocalMachine\Root" -Password $securePassword;
$cert = Import-PfxCertificate -FilePath "$certFullPath\$pfxFile" -CertStoreLocation "Cert:\LocalMachine\My" -Password $securePassword;
Write-Host "Certificate $($cert.Thumbprint) imported..."

Push-Location docker\traefik\config\dynamic
try {
    $sel = Select-String -Path .\certs_config.yaml -Pattern $ProjectPrefix
    if (!$sel)
    {
        Add-Content -Path certs_config.yaml -Value "`n    - certFile: C:\etc\traefik\certs\$ProjectPrefix.localhost.pem"
        Add-Content -Path certs_config.yaml -Value "      keyFile: C:\etc\traefik\certs\$ProjectPrefix.localhost-key.pem"    
    }
}
catch {
    Write-Host "An error occurred while attempting to updating certs_config.yaml: $_" -ForegroundColor Red
}
finally {
    Pop-Location
}