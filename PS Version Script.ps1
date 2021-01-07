#COM614
#Script to retrive Powershell Version

$version = Get-Host | Select-Object Version
Write-Host $version
Start-Sleep -Seconds 30
