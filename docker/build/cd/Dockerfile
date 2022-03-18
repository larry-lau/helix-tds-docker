# escape=`

ARG BASE_IMAGE
ARG TOOLING_IMAGE
ARG SOLUTION_IMAGE
ARG COVEO_ASSET

FROM ${SOLUTION_IMAGE} as solution
FROM ${TOOLING_IMAGE} as tooling
FROM ${COVEO_ASSET} as coveo
FROM ${BASE_IMAGE} as base

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit

# Set startmode to AlwaysRunning
RUN Import-Module WebAdministration; ` 
  Set-ItemProperty IIS:\AppPools\DefaultAppPool -Name startMode -Value 1; `
  Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name applicationDefaults.preloadEnabled -Value True;

# Copy and install self-signed certificates: Only for development purpose
COPY .\certs\ \certs\
WORKDIR C:\certs

RUN Import-Module IISAdministration; `
  $password = '1234'; `
  $securePassword = ConvertTo-SecureString -String $password -Force -AsPlainText; `
  Get-ChildItem -Path 'C:\certs\*.pfx' | % { `
    $certFile = $_.FullName; `
    $cert = Import-PfxCertificate -FilePath $certFile -CertStoreLocation "Cert:\LocalMachine\Root" -Password $securePassword; `
    $cert = Import-PfxCertificate -FilePath $certFile -CertStoreLocation "Cert:\LocalMachine\My" -Password $securePassword; `
    $cert = Import-PfxCertificate -FilePath $certFile -CertStoreLocation "Cert:\LocalMachine\Webhosting" -Password $securePassword; `  
    $thumbPrint = $cert.Thumbprint; `
    New-IISSiteBinding -Name 'Default Web Site' -BindingInformation '*:443:www.helix.localhost' -SslFlag "Sni" -CertificateThumbPrint $thumbPrint -CertStoreLocation 'Cert:\LocalMachine\Webhosting' -Protocol https; `
  };

# Copy development tools and entrypoint
COPY --from=tooling \tools\ \tools\

WORKDIR C:\inetpub\wwwroot

# Add Coveo module
COPY --from=coveo \module\cm\content .\

# Copy solution website files
COPY --from=solution \artifacts\website\ .\
COPY --from=solution \artifacts\data\App_Data\items\core\ .\App_Data\items\core\
COPY --from=solution \artifacts\data\App_Data\items\master\ .\App_Data\items\web\

# Copy role transforms
COPY .\transforms\ \transforms\role\

# Perform role transforms
RUN C:\tools\scripts\Invoke-XdtTransform.ps1 -Path .\ -XdtPath C:\transforms\role

RUN Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.SearchProvider.config.example Coveo.SearchProvider.config; `
    Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.SearchProvider.Rest.config.example Coveo.SearchProvider.Rest.config; `
    Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.UI.Controls.config.example Coveo.UI.Controls.config; `
    Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.UI.Components.ExperienceEditor.config.example Coveo.UI.Components.ExperienceEditor.config

RUN cmd /C icacls .\App_Config\Include\Coveo /grant 'IIS AppPool\DefaultAppPool:(OI)(CI)M'; `
    cmd /C icacls .\App_Config\Modules\Coveo /grant 'IIS AppPool\DefaultAppPool:(OI)(CI)M';

# Copy solution transforms
COPY --from=solution \artifacts\transforms\ \transforms\solution\

# Perform solution transforms
RUN C:\tools\scripts\Invoke-XdtTransform.ps1 -Path .\ -XdtPath C:\transforms\solution\BasicCompany.Web