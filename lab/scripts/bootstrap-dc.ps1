<#
.SYNOPSIS
    Configures minimal WinRM listener for Ansible management.
    Removes all self-contained Active Directory logic.
#>

param (
    [string]$DomainName = "corp.cloudlab.internal"
)

Start-Transcript -Path "C:\winrm-setup.log" -Append

try {
    # Minimal WinRM configuration for Ansible management
    winrm quickconfig -q
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'

    # Ensure firewall allows WinRM connections
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

    Write-Output "WinRM listener configured successfully."
}
catch {
    Write-Error $_
}
Stop-Transcript