$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

#COM614
#Script to automate Azure Deployment of GNS3
#Requires -RunAsAdministrator

#Variables
$location = "UKSouth"
$VMImage = "UbuntuLTS"
$VMsize = "Standard_D16_v3"

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

$ModCreateRG = {
    #Module to create the resource group
    Write-Host " "
    $global:ResourceGroup = Read-Host -Prompt "Enter name of wanted Resource Group`n"
    az group create --only-show-errors --name $global:ResourceGroup --location $Location | Out-Null
    Write-Output -Message ("`nResource group $global:ResourceGroup deployed`n")
}

$ModSetDefultRG = {
    #Sets default Azure CLI Resource Group
    az configure --defaults group=$global:ResourceGroup
    Write-Output -Message ("Default resource group set to : $global:ResourceGroup")
    }

$ModCreateVM = {
    #Create a VM, with set hostname, username, password, image

    #Collect Needed Info
    Write-Host " "
    $global:VMName = Read-Host -Prompt 'Enter name for the VM'
    Write-Host " "
    $global:VMAdminUsr = Read-Host -Prompt 'Enter username for the VM (Lowercase only)'
    Write-Host " "
    $global:VMAdminPwd = Read-Host -Prompt 'Enter password for the VM'

    #Use info to make VM
    az vm create --name $vmName --admin-username $global:VMAdminUsr --admin-password $global:VMAdminPwd --image $VMImage --size $VMsize
    Write-Output -Message ("VM $vmName Deployed")
}

$ModOpenSSHinRG = {
    #Opens SSH to internet
    az vm open-port --priority 1100 --port 22 --resource-group $global:ResourceGroup --name $global:VMName
    az vm open-port --priority 1200 --port 80 --resource-group $global:ResourceGroup --name $global:VMName 
    az vm open-port --priority 1300 --port 1194 --resource-group $global:ResourceGroup --name $global:VMName
    az vm open-port --priority 1400 --port 8003 --resource-group $global:ResourceGroup --name $global:VMName
}

$ModFindPublicIP = {
    #Finds the public IP of the VM to connect to
    Start-Sleep -Seconds 5
    $global:VMpublicSSHIP = (az vm show -d --resource-group $global:ResourceGroup --name $global:VMName --query publicIps --output tsv)
    Write-Output -Message ("PublicIP captured : $global:VMpublicSSHIP")
    Write-Output -Message ("$global:VMpublicSSHIP")

}

$ModOpenSSHSession = {
    #Module to create SSH session
    
    #Get Posh-SSH
    #Find-Module Posh-SSH | Install-Module -AllowClobber
    Install-Module PoSH-SSH -Force
    Import-Module Posh-SSH

    #Create Credentials
    $global:Password = ConvertTo-SecureString "$global:VMAdminPwd" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($global:VMAdminUsr, $global:Password)

    #Start Session
    $SSHSession = New-SSHSession -ComputerName "$global:VMpublicSSHIP" -Credential $credential -Port 22 -AcceptKey:$true

    #CollectID
    $global:SSHSession = $SSHSession.SessionID
}

$ModInvokeSSHCommands = {
    #Commands to run here
    Invoke-SSHCommand -Index $global:SSHSession -Command "uname"
    Invoke-SSHCommand -Index $global:SSHSession -Command "sudo add-apt-repository ppa:dawidd0811/neofetch -y"
    Invoke-SSHCommand -Index $global:SSHSession -Command "sudo apt update -y"
    Invoke-SSHCommand -Index $global:SSHSession -Command "sudo apt install neofetch -y"
    Invoke-SSHCommand -Index $global:SSHSession -Command "sudo cd /tmp"
    Invoke-SSHCommand -Index $global:SSHSession -Command "sudo curl https://raw.githubusercontent.com/GNS3/gns3-server/master/scripts/remote-install.sh > gns3-remote-install.sh" 
    Invoke-SSHCommand -Index $global:SSHSession -Command "sudo bash gns3-remote-install.sh --with-openvpn --with-iou --with-i386-repository" -TimeOut 3600
    Invoke-SSHCommand -Index $global:SSHSession -Command "sudo reboot"
}

$ModCloseSSHSession = {
    #Close Ran SSH Session
    Remove-SSHSession -SessionId $global:SSHSession
}

#Triggers
&$ModAZLogin
&$ModActiveSubSet
&$ModCreateRG
&$ModSetDefultRG
&$ModCreateVM
&$ModOpenSSHinRG
&$ModFindPublicIP
&$ModOpenSSHSession
&$ModInvokeSSHCommands
&$ModCloseSSHSession


$stopwatch
