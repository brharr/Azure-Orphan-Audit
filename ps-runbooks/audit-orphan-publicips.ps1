# Ensures you do not inherit an AzureRMContext in your runbook
Disable-AzureRmContextAutosave –Scope Process

$connection = Get-AutomationConnection -Name AzureRunAsConnection

# Wrap authentication in retry logic for transient network failures
$logonAttempt = 0
while(!($connectionResult) -And ($logonAttempt -le 10))
{
    $LogonAttempt++
    # Logging in to Azure...
    $connectionResult =    Connect-AzureRmAccount `
                               -ServicePrincipal `
                               -Tenant $connection.TenantID `
                               -ApplicationID $connection.ApplicationID `
                               -CertificateThumbprint $connection.CertificateThumbprint

    Start-Sleep -Seconds 30
}

$ips = Get-AzureRmPublicIpAddress
ForEach ($ip in $ips) {
    if ($ip.IpConfigurationText -eq "null") {
        # Need to figure out how to send information for an orphan, email etc.
        Write-Output("Orphan IP Found: " + $ip.Id)
    }
}