<#
   Date: 22/09/2020
   Purpose: Build Script of DynamoPrimer
#>
$ErrorActionPreference = "Stop"

try
{
	docker exec $env:DOCKER_CONTAINER pwsh -command "$env:DOCKER_WORKSPACE\$env:COMMON_RESOURCES_DIR\scripts\Build.ps1 -WorkspacePath $env:DOCKER_WORKSPACE"
	
	if($LASTEXITCODE -ne 0)
	{
		throw "The build-generation process failed"
	}
}
catch
{
	Invoke-Expression -Command "$env:WORKSPACE\$env:COMMON_RESOURCES_DIR\scripts\PostDeployScript.ps1"
	Write-Host $error[0]
	throw $LASTEXITCODE
}
