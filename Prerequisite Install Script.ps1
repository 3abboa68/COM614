$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

#COM614
#Script to automate Tool deployment.

#Stage 01 - Install tools
    #Limit to only adminstrators running - this is needed or Azure CLI fails silently due to lack of rights
    #Requires -RunAsAdministrator

    #Check that PS 5.1.19041.546 installed, and when present, install AZ module if compatable
    if ($PSVersionTable.PSVersion -eq '5.1.19041.546') {
        if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
            Write-Warning -Message ('Az module not installed. Having both the AzureRM and ' +
            'Az modules installed at the same time is not supported.')
        } else {
                Install-Module -Name Az -AllowClobber -Scope CurrentUser
                Write-Output -Message ('AZ module is installed')
        }
    } else {
        Write-Warning -Message ('PS Version incompatible with this script')
        Exit
    }

    #Install Azure CLI, then run updates (this ensures an existing install is current)
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
    Write-Output -Message ('Azure CLI on Windows installed')

    #Install SSH Sessions
    Install-Module -Name SSHSessions -Force
    Write-Output -Message ('SSHSessions installed')

    Write-Output -Message ('Stage 1 finished - tools installed')

#Stage 02 - Authenticate to Azure
    #Login to AZ via browser
    az login
    az interactive
$stopwatch 
