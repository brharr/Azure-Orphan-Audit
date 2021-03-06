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

$disks = Get-AzureRmDisk
ForEach ($disk in $disks) {
    if ($null -eq $disk.ManagedBy) {
        $type = "Microsoft.Compute/disks"
        $jsonOrphan = @{ 
            type = $type 
            id = $disk.Id 
        } | ConvertTo-Json

        $params = @{
            Uri         = $functionURL
            Method      = 'POST'
            Body        = $jsonOrphan
            ContentType = 'application/json'
        }
        Invoke-RestMethod @params
        Write-Output("Orphan Disk Found: " + $disk.Id)
    }
}