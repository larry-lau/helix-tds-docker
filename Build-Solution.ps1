param(
	[string]
	$MSBuildPath,
	[string]
	$Configuration = "Release",
	[string]
	$OutputPath = ".",
	$SolutionFile = "BasicCompany.sln",
	[Switch]$SkipRestore,
	[Switch]$SkipBuild,
	[Switch]$SkipTest,
	[Switch]$SkipCopy
)

if ($PSVersionTable.PSVersion.Major -lt 5) {
	Write-Error "You must be running PowerShell 5.1. See https://www.microsoft.com/en-us/download/details.aspx?id=54616"
	exit
}

$OutputPath = (Get-Item $OutputPath).FullName
$PackageOutputPath = Join-Path $OutputPath TdsGeneratedPackages
$WebsiteOutputPath = Join-Path $OutputPath _publish

if (!$SkipRestore)
{
	nuget restore $SolutionFile
}

if (!$SkipBuild)
{
	if(-not $MSBuildPath) {
		$MSBuildPath = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe
	}
	
	if(Test-Path $WebsiteOutputPath) {
		Remove-Item -Path $WebsiteOutputPath -Recurse -Force
	}
	
	if(Test-Path $PackageOutputPath) {
		Remove-Item -Path $PackageOutputPath -Recurse -Force
	}
	
	#& $MSBuildPath $SolutionFile /p:Configuration=$Configuration /p:DeployOnBuild=True /p:DeployDefaultTarget=WebPublish /p:DebugSymbols=false /p:DebugType=None
	& $MSBuildPath $SolutionFile /p:Configuration=$Configuration /p:DeployOnBuild=True /p:DeployDefaultTarget=WebPublish /p:WebPublishMethod=FileSystem /p:PublishUrl=$WebsiteOutputPath /p:DebugSymbols=false /p:DebugType=None
}

if (!$SkipTest)
{
	$VSTestPath = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -property installationPath

	Get-ChildItem -Path . -Filter *.Tests.dll -Recurse | % {
		$testDll = $_.FullName
		& "$VSTestPath\Common7\IDE\Extensions\TestPlatform\vstest.console.exe" $testDll
	}	
}

if (!$SkipCopy)
{
	#xcopy /Y /I .\TdsGeneratedPackages\Package_Release $PackageOutputPath

	# Remove bin with all dependent dlls
	Remove-Item -Path $PackageOutputPath\Release\bin -Recurse -Force
	
	# Copy Custom dlls only
	Copy-Item -Path "$WebsiteOutputPath\bin" -Destination $PackageOutputPath\Release\bin -Recurse

	# COPY App_Data\* 
	Get-ChildItem -Path src -Filter "App_Data" -Recurse | % { Copy-Item -Path $_.FullName -Destination $PackageOutputPath\Release -Recurse -Force }
	
	# COPY Master to Web
	Copy-Item -Path "$PackageOutputPath\Release\App_Data\items\master" -Filter *.dat -Destination $PackageOutputPath\Release\App_Data\items\web -Recurse
}
