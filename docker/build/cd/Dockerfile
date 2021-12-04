# escape=`

ARG BASE_IMAGE
ARG TOOLING_IMAGE
ARG SOLUTION_IMAGE
ARG COVEO_ASSET
ARG COVEO_ENABLE

FROM ${SOLUTION_IMAGE} as solution
FROM ${TOOLING_IMAGE} as tooling
FROM ${COVEO_ASSET} as coveo
FROM ${BASE_IMAGE} as base

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Copy development tools and entrypoint
COPY --from=tooling \tools\ \tools\

WORKDIR C:\inetpub\wwwroot

# Add Coveo module
COPY --from=coveo \module\cm\content .\

# Copy solution website files
COPY --from=solution \artifacts\website\ .\
COPY --from=solution \artifacts\data\App_Data\items\core\ .\App_Data\items\core\
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

RUN cmd /C icacls .\App_Config\Include\Coveo /grant 'IIS AppPool\DefaultAppPool:(OI)(CI)M'; `
    cmd /C icacls .\App_Config\Modules\Coveo /grant 'IIS AppPool\DefaultAppPool:(OI)(CI)M';

# Copy solution transforms
COPY --from=solution \artifacts\transforms\ \transforms\solution\

# Perform solution transforms
RUN C:\tools\scripts\Invoke-XdtTransform.ps1 -Path .\ -XdtPath C:\transforms\solution\BasicCompany.Web