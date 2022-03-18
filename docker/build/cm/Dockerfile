# escape=`

ARG BASE_IMAGE
ARG SPE_IMAGE
ARG TOOLING_IMAGE
ARG SOLUTION_IMAGE
ARG COVEO_ASSET

FROM ${SOLUTION_IMAGE} as solution
FROM ${TOOLING_IMAGE} as tooling
FROM ${SPE_IMAGE} as spe
FROM ${COVEO_ASSET} as coveo
FROM ${BASE_IMAGE} as base

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit

# Set startmode to AlwaysRunning
RUN Import-Module WebAdministration; ` 
  Set-ItemProperty IIS:\AppPools\DefaultAppPool -Name startMode -Value 1; `
  Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name applicationDefaults.preloadEnabled -Value True

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
    New-IISSiteBinding -Name 'Default Web Site' -BindingInformation '*:443:cm.helix.localhost' -SslFlag "Sni" -CertificateThumbPrint $thumbPrint -CertStoreLocation 'Cert:\LocalMachine\Webhosting' -Protocol https; `
  };

# Copy development tools and entrypoint
COPY --from=tooling \tools\ \tools\

WORKDIR C:\inetpub\wwwroot

# Copy role transforms
COPY .\transforms\ \transforms\role\

# Perform role transforms
RUN C:\tools\scripts\Invoke-XdtTransform.ps1 -Path .\ -XdtPath C:\transforms\role

# Add SPE module
COPY --from=spe \module\cm\content .\

# Add Coveo module
COPY --from=coveo \module\cm\content .\

# Copy solution website files
COPY --from=solution \artifacts\website\ .\
COPY --from=solution \artifacts\data\App_Data\items\core\ .\App_Data\items\core\
COPY --from=solution \artifacts\data\App_Data\items\master\ .\App_Data\items\master\
COPY --from=solution \artifacts\data\App_Data\items\master\ .\App_Data\items\web\

RUN Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.SearchProvider.config.example Coveo.SearchProvider.config; `
    Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.SearchProvider.Rest.config.example Coveo.SearchProvider.Rest.config; `
    Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.UI.Controls.config.example Coveo.UI.Controls.config; `
    Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.UI.Components.ExperienceEditor.config.example Coveo.UI.Components.ExperienceEditor.config

# Copy solution transforms
COPY --from=solution \artifacts\transforms\ \transforms\solution\

# Perform solution transforms
RUN C:\tools\scripts\Invoke-XdtTransform.ps1 -Path .\ -XdtPath C:\transforms\solution\BasicCompany.Web

# Include TDS Item packages (2 options)

# OPTION 1: Allow TDS to install on startup, knowing this will be done on EVERY container create
# COPY --from=solution \artifacts\packages\ \temp\
# RUN Get-ChildItem -Path 'C:\\temp\\*.wdp.zip' | % { Expand-Archive -Path $_.FullName -DestinationPath 'C:\\temp' -Force; }; `
#     Move-Item -Path 'C:\\temp\\Content\\Website\\Bin\*' -Destination .\bin -Force; `
#     Move-Item -Path 'C:\\temp\\Content\\Website\\temp\*' -Destination .\temp -Force; `
#     Remove-Item -Path 'C:\\temp' -Recurse -Force; `
#     # Ensure TDS has permissions to delete items after install
#     cmd /C icacls .\temp\WebDeployItems /grant 'IIS AppPool\DefaultAppPool:(OI)(CI)M';

# OPTION 2: Invoke Deploy-TdsWdpPackages.ps1 on the container as-needed (similar to Unicorn sync) with the following script:
#   docker exec <cm container> powershell -command "C:\install\Deploy-TdsWdpPackages.ps1"
# COPY --from=tooling \tools\scripts\Deploy-TdsWdpPackages.ps1 \install\Deploy-TdsWdpPackages.ps1
# COPY --from=solution \artifacts\packages\ \install\packages\

# OPTION 3: Use Item Resource file .dat