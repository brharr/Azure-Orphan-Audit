# Ensures you do not inherit an AzureRMContext in your runbook
Disable-AzureRmContextAutosave –Scope Process

$connection = Get-AutomationConnection -Name AzureRunAsConnection
$functionURL = Get-AzureAutomationVariable -Name OrphanFunctionURL

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
        # Send data to an Azure Function to store in a Azure Queue
        $type = "Microsoft.Network/publicIPAddresses"
        $jsonOrphan = @{ 
            type = $type 
            id = $ip.Id 
        } | ConvertTo-Json

        $params = @{
            Uri         = $functionURL
            Method      = 'POST'
            Body        = $jsonOrphan
            ContentType = 'application/json'
        }
        Invoke-RestMethod @params
        Write-Output("Orphan IP Found: " + $ip.Id)
    }
}