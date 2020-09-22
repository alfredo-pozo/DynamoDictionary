<#
   Date: 22/09/2020
   Purpose: Run the deploy commands inside container.
#>
param(
   [String]  
   $BucketName,
   [String]
   $DistributionID,
   [String]
   $ContentRoot
)

$ErrorActionPreference = "Stop"

Function RemoveS3Object {
   param (
      [string]$s3Key
   )
   Write-Host $s3Key
   Remove-S3Object -BucketName $AWSBucketName -Key $s3Key -Force  
}

Function RemoveS3Folder {
   param (
      [string]$s3Prefix, $filter
   )
   if ([string]::IsNullOrEmpty($s3Prefix))
   {
      $objectList = Get-S3Object -BucketName $AWSBucketName | Where-Object $filter
   }
   else
   {
      $objectList = Get-S3Object -BucketName $AWSBucketName -Prefix "$s3Prefix/"
   }
   Write-Host "Deleting $s3Prefix ..."
   foreach($myObject in $objectList){
      RemoveS3Object -s3Key $myObject.Key
   }
   Write-Host "Deletion complete of $s3Prefix!"   
}

Function UploadS3Object {
   param (
      [string]$localPath, [string]$prefixWhitPath
   )
   Write-Host $prefixWhitPath
   Write-S3Object -BucketName $AWSBucketName -File $localPath -Key $prefixWhitPath   
}

Function UploadS3Folder {
   param (
      [string]$localFolderLocation, [string]$s3Prefix
   )
   $results = Get-ChildItem "$localFolderLocation" -File -Recurse
   Write-Host "Uploading $s3Prefix ..."
   foreach ($path in $results) {
      $keyPath = $path.FullName.Replace($localFolderLocation + "\","").Replace("\","/")

      if ([string]::IsNullOrEmpty($s3Prefix))
      {
        UploadS3Object -localPath $path.FullName -prefixWhitPath "$keyPath"
      }
      else
      {      
        UploadS3Object -localPath $path.FullName -prefixWhitPath "$s3Prefix/$keyPath"
      }
   }
   Write-Host "Upload complete for $s3Prefix!" 
}

try {
      
   #Vault
   $jsonToken = &vault write -address=https://civ1.dv.adskengineer.net:8200 -format=json /account/572569678988/sts/Application-Ops ttl=4h | ConvertFrom-Json
   
   if($LASTEXITCODE -ne 0)
   {
      throw "The Vault Write to get AWS token failed"
   }
   
   Write-Host $jsonToken.request_id

   #AWS variables
   $AWSRegion = "us-east-1"
   $AWSBucketName = $bucketName
   $s3folder = "2"

   #Set credentials
   Set-AWSCredential -AccessKey $jsonToken.data.access_key -SecretKey $jsonToken.data.secret_key -SessionToken $jsonToken.data.security_token

   #Remove old content
   Write-Host "Removing old content ..."
   RemoveS3Folder -s3Prefix $s3folder -filter $null

   #Get all files and upload
   Write-Host "Uploading new content ..."
   UploadS3Folder -localFolderLocation "$ContentRoot" -s3Prefix $s3folder

   #Invalidating current CDN content to refresh it
   $invalidationLong = [long](Get-Date -Format "yyyddMMHHmm")
   New-CFInvalidation -DistributionId $distributionID -InvalidationBatch_CallerReference $invalidationLong -Paths_Item "/*" -Paths_Quantity 1 -Region $AWSRegion

}
catch {
   Write-Host $error[0]
	throw $LASTEXITCODE
}
