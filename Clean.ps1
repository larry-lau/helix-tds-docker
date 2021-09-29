param(	
	[Switch]$Solution,
	[Switch]$Docker
)

if ($Solution)
{
    $MSBuildPath = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe
    & $MSBuildPath /p:Configuration=Debug /t:Clean
    & $MSBuildPath /p:Configuration=Release /t:Clean
    
    $foldersToClean = @('_publish', 'TdsGeneratedPackages', 'packages')
    $foldersToClean | % {
        if (Test-Path $_) { Remove-Item -Path $_ -Force -Recurse }    
    }    
    Get-ChildItem -Path . -Filter bin -Recurse | Remove-Item -Force -Recurse
    Get-ChildItem -Path . -Filter obj -Recurse | Remove-Item -Force -Recurse
    Get-ChildItem -Path . -Filter ItemResources_* -Recurse | Remove-Item -Force -Recurse    
}

if ($Docker)
{
    Get-ChildItem -Path (Join-Path $PSScriptRoot "\docker\data\cd") -Exclude ".gitkeep" -Recurse | Remove-Item -Force -Recurse -Verbose
    Get-ChildItem -Path (Join-Path $PSScriptRoot "\docker\data\cm") -Exclude ".gitkeep" -Recurse | Remove-Item -Force -Recurse -Verbose
    Get-ChildItem -Path (Join-Path $PSScriptRoot "\docker\data\mssql") -Exclude ".gitkeep" -Recurse | Remove-Item -Force -Recurse -Verbose
    Get-ChildItem -Path (Join-Path $PSScriptRoot "\docker\data\solr") -Exclude ".gitkeep" -Recurse | Remove-Item -Force -Recurse -Verbose
    Get-ChildItem -Path (Join-Path $PSScriptRoot "\docker\deploy\website") -Exclude ".gitkeep" -Recurse | Remove-Item -Force -Recurse -Verbose    
}

docker image prune -f