<#
.SYNOPSIS
    Waits for the Domain Controller to be healthy, then joins the domain.
#>

param (
    [string]$DomainName = "corp.cloudlab.internal",
    [string]$AdminPassword,     # Domain Admin password for the join operation
    [string]$DcIP               # The IP of the DC (10.10.1.10)
)

Start-Transcript -Path "C:\provisioning-client.log" -Append

try {
    # 1. Point DNS to the DC
    # Crucial: We must ignore AWS DNS and look strictly at our new DC.
    $Interface = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
    Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses $DcIP

    # 2. The Wait Loop
    # We loop until the Domain Name resolves. This proves the DC is up and DNS is running.
    $MaxRetries = 40 # 40 * 15s = ~10 minutes wait time
    $RetryCount = 0
    $DomainReady = $false

    while (-not $DomainReady -and $RetryCount -lt $MaxRetries) {
        try {
            $Test = Resolve-DnsName -Name $DomainName -Type A -ErrorAction Stop
            if ($Test) {
                Write-Output "Domain $DomainName detected! Proceeding..."
                $DomainReady = $true
            }
        }
        catch {
            Write-Output "Waiting for Domain Controller... ($RetryCount / $MaxRetries)"
            Start-Sleep -Seconds 15
            $RetryCount++
        }
    }

    # 3. Join the Domain
    if ($DomainReady) {
        $pwd = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential("Administrator", $pwd)

        Add-Computer -DomainName $DomainName -Credential $cred -Restart -Force
    } else {
        Throw "Timed out waiting for DC ($DcIP). Check Security Groups or DC status."
    }
}
catch {
    Write-Error $_
}
finally {
    Stop-Transcript
}