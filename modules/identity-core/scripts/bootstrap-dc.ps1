<#
.SYNOPSIS
    Orchestrates the promotion of a Windows Server Core instance to a DC.
    Handles the "Rename + Reboot" requirement automatically.
#>

param (
    [string]$DomainName = "corp.cloudlab.internal", 
    [string]$SafeModePassword, 
    [string]$StaticIP
)

Start-Transcript -Path "C:\provisioning-dc.log" -Append

try {
    # -------------------------------------------------------------------------
    # 1. Network Configuration
    # -------------------------------------------------------------------------
    $Interface = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
    
    New-NetIPAddress -InterfaceIndex $Interface.InterfaceIndex `
        -IPAddress $StaticIP -PrefixLength 24 -DefaultGateway "10.10.1.1" -ErrorAction SilentlyContinue

    Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses "127.0.0.1"
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

    # -------------------------------------------------------------------------
    # 2. Rename & Reboot Strategy
    # -------------------------------------------------------------------------
    $CurrentName = $env:COMPUTERNAME
    $TargetName  = "DC01"

    if ($CurrentName -ne $TargetName) {
        Write-Output "Renaming to $TargetName..."
        Rename-Computer -NewName $TargetName -Force

        $ActionArgs = "-ExecutionPolicy Bypass -File C:\bootstrap-dc.ps1 -DomainName $DomainName -SafeModePassword '$SafeModePassword' -StaticIP $StaticIP"
        
        $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $ActionArgs
        $Trigger = New-ScheduledTaskTrigger -AtStartup
        Register-ScheduledTask -TaskName "ResumeProvisioning" -Action $Action -Trigger $Trigger -User "SYSTEM" -RunLevel Highest

        Write-Output "Rebooting to apply name change..."
        Restart-Computer -Force
        exit 
    }

    # -------------------------------------------------------------------------
    # 3. Phase 2 Execution (Post-Reboot)
    # -------------------------------------------------------------------------
    Unregister-ScheduledTask -TaskName "ResumeProvisioning" -Confirm:$false -ErrorAction SilentlyContinue

    $AdminUser = [ADSI]"WinNT://./Administrator,user"
    $AdminUser.SetPassword($SafeModePassword)
    net user Administrator /active:yes
    
    Start-Sleep -Seconds 30

    # -------------------------------------------------------------------------
    # 4. Active Directory Installation & Promotion
    # -------------------------------------------------------------------------
    Write-Output "Installing AD DS binaries..."
    Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools

    $DomainExists = (Get-WmiObject Win32_ComputerSystem).Domain -eq $DomainName

    if (-not $DomainExists) {
        Write-Output "Promoting to Domain Controller for $DomainName..."
        
        $SecurePassword = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force

        Install-ADDSForest `
            -DomainName $DomainName `
            -SafeModeAdministratorPassword $SecurePassword `
            -InstallDns:$true `
            -Force:$true `
            -Confirm:$false
    } else {
        Write-Output "Server is already a member of $DomainName."
    }
}
catch {
    Write-Error $_
}
Stop-Transcript