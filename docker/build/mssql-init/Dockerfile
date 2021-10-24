# escape=`

ARG BASE_IMAGE
ARG SPE_IMAGE

FROM ${SPE_IMAGE} as module_assets
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Add SPE module
COPY --from=module_assets C:\module\db c:\resources\spe
