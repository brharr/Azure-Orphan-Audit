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

$disks = Get-AzureRmDisk
ForEach ($disk in $disks) {
    if ($null -eq $disk.ManagedBy) {
        Write-Output("Orphan Disk Found: " + $disk.Id)
    }
}