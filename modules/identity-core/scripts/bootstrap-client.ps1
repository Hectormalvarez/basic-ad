<#
.SYNOPSIS
    Orchestrates the convergence of a Member Server into the Active Directory domain.
#>

param (
    [string]$DomainName = "corp.cloudlab.internal",
    [string]$AdminUser = "CloudAdmin", 
    [string]$AdminPassword,
    [string]$DcIP
)

Start-Transcript -Path "C:\provisioning-client.log" -Append

try {
    # -------------------------------------------------------------------------
    # 1. DNS Configuration
    # -------------------------------------------------------------------------
    $Interface = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
    Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses $DcIP

    # -------------------------------------------------------------------------
    # 2. The Wait Loop (Connectivity Check)
    # -------------------------------------------------------------------------
    $MaxRetries = 60 
    $RetryCount = 0
    $DomainReady = $false

    while (-not $DomainReady -and $RetryCount -lt $MaxRetries) {
        # Check Port 389 (LDAP) to verify AD is listening
        $Connection = Test-NetConnection -ComputerName $DcIP -Port 389 -WarningAction SilentlyContinue
        
        if ($Connection.TcpTestSucceeded) {
            Write-Output "DC is reachable on Port 389 (LDAP)! Proceeding..."
            $DomainReady = $true
        }
        else {
            Write-Output "Waiting for DC Connectivity (Port 389)... ($RetryCount / $MaxRetries)"
            Start-Sleep -Seconds 15
            $RetryCount++
        }
    }

    # -------------------------------------------------------------------------
    # 3. Join Domain
    # -------------------------------------------------------------------------
    if ($DomainReady) {
        Start-Sleep -Seconds 10 
        
        $pwd = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
        
        # Construct the UPN for CloudAdmin (e.g., CloudAdmin@corp.cloudlab.internal)
        $UPN = "$AdminUser@$DomainName"
        $cred = New-Object System.Management.Automation.PSCredential($UPN, $pwd)

        Write-Output "Joining domain $DomainName as $UPN..."
        
        Add-Computer -DomainName $DomainName -Credential $cred -Restart -Force
    } else {
        Throw "Timed out waiting for DC ($DcIP)."
    }
}
catch {
    Write-Error $_
}
Stop-Transcript