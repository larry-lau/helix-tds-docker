# Running the Example

## Prerequisites

- The solution requires you have some experience with (or at least an understanding of) Docker container-based Sitecore development. For more information, see the [Sitecore Containers Documentation](https://containers.doc.sitecore.com).

- Microsoft Windows 10 Professional or Enterprise 64-bit, or Windows 10 Home 64-bit with WSL 2. 

- Docker Desktop for Windows with with Docker Engine version 19.03.0 and higher.
Note: Sitecore Containers run on Windows-base image. It will not run on macOS.

- Visual Studio 2019, Visual Studio Code, or [Build Tools for Visual Studio 2019](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2019) installed with the additional Web Development Build Tools option selected

- [Sitecore TDS v6.0.0.31](https://www.teamdevelopmentforsitecore.com/Download/TDS-Classic) or higher. If you do not have a license, you can [obtain a trial license](https://www.teamdevelopmentforsitecore.com/TDS-Classic/Free-Trial).

- A valid Sitecore license file license.xml
PowerShell 5.1 or higher
- [Github Desktop](https://desktop.github.com/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli)

## Local development Setup (one time)

- Select the "Switch to Windows containers" option in the system tray Docker menu because Sitecore images only run in Windows container mode

- Disable Windows Defender Antivirus or exclude the path %ProgramData%\docker as this may cause CPU/memory usage problems.

  - Go to Start > Settings > Update & Security > Windows Security > Virus & threat protection. Under Virus & threat protection settings, select Manage settings, and then under Exclusions, select Add or remove exclusions.

- Enable longpath for git. Otherwise, git clone may fail.
    ```
    git config --system core.longpaths true
    ```

- Clone this repository into a directory with a short path as a long path will result in build errors.

- Copy your Sitecore license file to the install-assets folder with file name license.xml  

- Open a PowerShell administrator prompt and run the following command 
    ```
    .\docker-init.ps1 -Env xp0
    ```
> This will perform any necessary preparation steps, such as populating the Docker Compose environment (.env) file, configuring certificates, and adding hosts file entries.

> A .env file will be generated from .env-sample and .env file is ignored by git so secret don't get committed in repo.  You are responsible for maintaining this file since it contains your secrets.

- Set TDS license environment variables with your TDS license details to the .env file:

  * `TDS_OWNER`
  * `TDS_KEY`

## Obtain Coveo Farm settings for your environment

1. Create API Key and Search API Key in [Coveo Admin Console](https://platform.cloud.coveo.com). Please refer to [Privileges for the SearchApiKey](https://docs.coveo.com/en/2484/coveo-for-sitecore-v5/activate-coveo-for-sitecore-silently#privileges-for-the-searchapikey)
and [Privileges for the ApiKey](https://docs.coveo.com/en/2484/coveo-for-sitecore-v5/activate-coveo-for-sitecore-silently#privileges-for-the-searchapikey)
2. Populate these environment variables
    ```
    COVEO_ENABLE=true
    COVEO_API_KEY=xxxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    COVEO_SEARCH_API_KEY=xxxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    COVEO_ORG_ID=xxxxxxxxxxxxxxxxx
    COVEO_FARMNAME=xxxxxxxxxxx
    ````
3. Run the coveo-init script in Administrative mode
    ```
    .\coveo-init.ps1
    ```
    Note: this command encrypt the keys and add the encrypted env variables to .env. 
    
## Build the solution and start Sitecore in Docker

This repo supports three Sitecore topoloiesy xm1, xp0 and xp1. The compose files are organzied in their own folder respectively. 
- Use XM1 if your system memory < 8Gb, 
- Use XP0 if your system memory < 16 Gb 
- Use XP1 if your system memory > 16 Gb 

## Seleect topology
Run the following command in PowerShell.

```
cd xp0
```
## Build the solution
Run the following command in PowerShell.

```
docker-compose build --force-rm
```

Note: It takes about a few minutes the first time since docker has to download a few large Window images.

## Start Sitecore
Run the following command in PowerShell.
```
docker-compose up -d
```

This will download any required Docker images, build the solution and Sitecore runtime images, and then start the containers. 

Once complete, you can access the instance with the following.

* Sitecore Content Management: https://cm.helix.localhost
* Sitecore Identity Server: https://id.helix.localhost
* Basic Company site: https://www.helix.localhost

## Publish

The serialized items will automatically sync when the instance is started, but you'll need to publish them.

Login to Sitecore at https://cm.helix.localhost/sitecore. Ensure the items are done deploying (look for `/sitecore/content/Basic Company`), and perform a site smart publish. Use "admin" and the password you specified on init ("b" by default).

> For the _Products_ page to work, you'll also need to _Populate Solr Managed Schema_ and rebuild indexes from the Control Panel. You may also need to `docker-compose restart cd` due to workaround an issue with the Solr schema cache on CD.

You should now be able to view the Basic Company site at https://www.helix.localhost.

## Stop Sitecore

When you're done, stop and remove the containers using the following command.

```
docker-compose down
```

## Troubleshooting

### Attach to running container
Run the following command to attach to the cd role
```
docker-compose exec cd cmd.exe
```

### Check required ports
Run the following command in PowerShell.

```
.\docker\Check-Ports.ps1
```

### Working with IIS side-by-side
If you can't stop the IIS for some reason, you can use a different port traefik. Update your compose file such follow. 

```
  traefik:
    ports:
      - "8443:443" #coexist with IIS
```

### Working with Coveo

### Copy files from container
docker cp 5a605853b48a:C:\inetpub\wwwroot\App_Config\Include\Coveo C:\Test\folder2

Error response from daemon: filesystem operations against a running Hyper-V container are not supported