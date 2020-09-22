<#
   Date: 22/09/2020
   Purpose: Build inside container.
#>
$ErrorActionPreference = "Stop"

try
{
   npm install

   if($LASTEXITCODE -ne 0)
   {
      throw "Installation Failed"
   }

   npm run build
      
   if($LASTEXITCODE -ne 0)
   {
      throw "Build Failed"
   }
}
catch
{
	Write-Host $error[0]
	throw $LASTEXITCODE
}
