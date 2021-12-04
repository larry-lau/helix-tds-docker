# escape=`

ARG BASE_IMAGE
ARG SPE_IMAGE
ARG TOOLING_IMAGE
ARG SOLUTION_IMAGE
ARG COVEO_ASSET
ARG COVEO_ENABLE

FROM ${SOLUTION_IMAGE} as solution
FROM ${TOOLING_IMAGE} as tooling
FROM ${SPE_IMAGE} as spe
FROM ${COVEO_ASSET} as coveo
FROM ${BASE_IMAGE} as base

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Copy development tools and entrypoint
COPY --from=tooling \tools\ \tools\

WORKDIR C:\inetpub\wwwroot

# Add SPE module
COPY --from=spe \module\cm\content .\

# Add Coveo module
COPY --from=coveo \module\cm\content .\

# Copy solution website files
COPY --from=solution \artifacts\website\ .\
COPY --from=solution \artifacts\data\App_Data\items\core\ .\App_Data\items\core\
COPY --from=solution \artifacts\data\App_Data\items\master\ .\App_Data\items\master\
COPY --from=solution \artifacts\data\App_Data\items\master\ .\App_Data\items\web\

FROM base AS activate-coveo-true
RUN echo "Coveo is activated"
RUN Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.SearchProvider.config.example Coveo.SearchProvider.config; `
    Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.SearchProvider.Rest.config.example Coveo.SearchProvider.Rest.config; `
    Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.UI.Controls.config.example Coveo.UI.Controls.config; `
    Rename-Item C:\inetpub\wwwroot\App_Config\Modules\Coveo\Coveo.UI.Components.ExperienceEditor.config.example Coveo.UI.Components.ExperienceEditor.config

FROM base AS activate-coveo-false
RUN echo "Coveo is not activated"
RUN Remove-Item C:\inetpub\wwwroot\App_Config\Include\Coveo\Coveo.CloudPlatformClient.Custom.config; `
    Remove-Item C:\inetpub\wwwroot\App_Config\Include\Coveo\Coveo.SearchProvider.Custom.config; `
    Remove-Item C:\inetpub\wwwroot\App_Config\Include\Coveo\Coveo.SearchProvider.Rest.Custom.config

FROM activate-coveo-${COVEO_ENABLE} AS final

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