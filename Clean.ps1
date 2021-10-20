param(	
	[Switch]$Solution,
	[Switch]$Docker,
    [Switch]$Data
)

if ($Solution)
{
    $MSBuildPath = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe
    & $MSBuildPath /p:Configuration=Debug /t:Clean
    & $MSBuildPath /p:Configuration=Release /t:Clean
    
    $foldersToClean = @('_data', '_publish', 'TdsGeneratedPackages', 'packages')
    $foldersToClean | % {
        $folder = Join-Path $PSScriptRoot $_
        if (Test-Path $_) { Remove-Item -Path $folder -Force -Recurse }    
    }    

    $srcPath = (get-item "$PSScriptRoot\src").FullName
    Get-ChildItem -Path $srcPath -Filter bin -Recurse | Remove-Item -Force -Recurse
    Get-ChildItem -Path $srcPath -Filter obj -Recurse | Remove-Item -Force -Recurse
    Get-ChildItem -Path $srcPath -Filter ItemResources_* -Recurse | Remove-Item -Force -Recurse    
}

if ($Docker)
{
    # Clean deploy folders
    Get-ChildItem -Path (Join-Path "$PSScriptRoot\docker" "\deploy") -Directory | ForEach-Object {
        $deployPath = $_.FullName

        Get-ChildItem -Path $deployPath -Exclude ".gitkeep" -Recurse | Remove-Item -Force -Recurse -Verbose
    }    
    docker image prune -f
}

if ($Data)
{
    if (Test-Path ".\data") { 
        # Clean data folders
        Get-ChildItem -Path (Join-Path "." "\data") -Directory | ForEach-Object {
            $dataPath = $_.FullName

            Get-ChildItem -Path $dataPath -Exclude ".gitkeep" -Recurse | Remove-Item -Force -Recurse -Verbose
        }
    }
}