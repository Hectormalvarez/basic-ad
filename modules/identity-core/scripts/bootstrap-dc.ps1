<#
.SYNOPSIS
    Orchestrates the promotion of a Windows Server Core instance to a DC.
    Designed for Cloud-Init / UserData injection.
#>

param (
    [string]$DomainName = "corp.cloudlab.internal", 
    [string]$SafeModePassword, # Passed via Terraform sensitive vars
    [string]$StaticIP           # The private IP we reserved in the subnet
)

# Start logging everything to C:\ for debugging
Start-Transcript -Path "C:\provisioning-dc.log" -Append

try {
    # 1. Network Configuration (The Anchor)
    # Windows Cloud images default to DHCP. We force a static IP to ensure DNS stability.
    $Interface = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
    
    # We use ErrorAction SilentlyContinue because on a re-run, this might already be set
    New-NetIPAddress -InterfaceIndex $Interface.InterfaceIndex `
        -IPAddress $StaticIP -PrefixLength 24 -DefaultGateway "10.10.1.1" -ErrorAction SilentlyContinue

    # Set DNS to localhost (127.0.0.1) so the DC looks at itself for answers
    Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses "127.0.0.1"

    # 2. Disable Firewall Profiles (LAB ONLY)
    # In a real prod environment, we would open specific ports (53, 389, 88, etc.)
    # For this lab, we turn it off to guarantee connectivity during troubleshooting.
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

    # 3. Rename the Computer
    # A standard random AWS hostname like 'IP-10-10-1-50' is ugly. We want 'DC01'.
    $CurrentName = (Get-ComputerInfo).CsName
    if ($CurrentName -ne "DC01") {
        Rename-Computer -NewName "DC01" -Force
    }

    # 4. Install Active Directory Domain Services
    Write-Output "Installing AD DS binary files..."
    Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools

    # 5. Promote to Domain Controller (The Point of No Return)
    $DomainExists = (Get-WmiObject Win32_ComputerSystem).Domain -eq $DomainName

    if (-not $DomainExists) {
        Write-Output "Promoting server to Domain Controller for $DomainName..."
        
        $pwd = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
        
        Install-ADDSForest `
            -DomainName $DomainName `
            -SafeModeAdministratorPassword $pwd `
            -InstallDns:$true `
            -Force:$true `
            -Confirm:$false
            
        # The server will automatically reboot here to finalize the promotion.
    } else {
        Write-Output "Server is already a member of $DomainName. Skipping promotion."
    }
}
catch {
    Write-Error $_
}
finally {
    Stop-Transcript
}