$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

#COM614
#Script to clean up after POC
#Requires -RunAsAdministrator

#Modules
$ModAzLogin = {
    #Module to log into azure
    Clear-Host
    Write-Host "`nYou need to log into Azure :`n"
    az login  --only-show-errors --output none | Out-Null
    Start-Sleep 5
    Clear-Host
    }

$ModActiveSubSet = {
    #Module to set Subscription
    Clear-Host
    Write-Host "`nYou need to set an active Subscription. Here are your availible Subscriptions :`n"
    az account list --output table --query '[].{name: name}'
    Write-Host " "
    $global:AZSubWanted = Read-Host -Prompt 'Enter Subscription to use '
    $AZSubList = az account list --output table --query '[].{name: name}'
    if ($AZSubList -contains $global:AZSubWanted) {
          az account set --subscription $global:AZSubWanted 
          Clear-Host
          Write-Host "`nSubscription set to $global:AZSubWanted"
          Start-Sleep 3
          } 
    else  {
           Write-Warning "$global:AZSubWanted not found. Please select valid Subscription"
           Start-Sleep 10
           &$ModActiveSubSet
          }

    }

$ModRGDestroy = {
    #Module to set Subscription
    Clear-Host
    Write-Host "`nEnter the name of a Resource Group to remove. All content will be destroyed :`n"
    az group list --output table --query '[].{name: name}'
    Write-Host " "
    $global:AZSubWanted = Read-Host -Prompt 'Enter Resource Group to destroy '
    $AZRGList = az group list --output table --query '[].{name: name}'
    if ($AZSRGList -contains $global:AZRGWanted) {
          az group delete --name $global:AZSubWanted --no-wait
          Write-Host "`n$global:AZRGWanted has been destroyed"
          Start-Sleep 3
          } 
    else  {
           Write-Warning "$global:AZRGWanted not found. Please select Resource Group"
           Start-Sleep 10
           &$ModActiveSubSet
          }

    }

#Triggers
&$ModAZLogin
&$ModActiveSubSet
&$ModRGDestroy
