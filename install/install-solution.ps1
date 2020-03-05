# Please keep in mind that this script was put together with the intent that it would be run
# inside of Azure Cloud Shell, therefore all Authentication has been kept out of the script.

$location = "<region designation>"
$resourceGroup = "<resource group name>"
$autoAccountName = "<automation account name>"
$storageName = "<storage account name>"
$functionAppName = "<azure function app name>"
$functionOrphanURL = "https://" + $functionAppName + ".azurewebsites.net/api/AzureOrphanHttpTrigger"

New-AzResourceGroup -Name $resourceGroup -Location $location

$storageAcct = New-AzStorageAccount -ResourceGroupName $resourceGroup -Location $location -Name $storageName -AccessTier Hot -Kind StorageV2 -SkuName Standard_LRS
$ctx = $storageAcct.Context
New-AzStorageQueue -Name orphans -Context $ctx
New-AzStorageQueue -Name auditreports -Context $ctx
$accountKey1 = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -AccountName $storageName).Value[0]

$azureDeployHash = @{ location = $location; appName = $functionAppName; runtime = "node"; storageAccountName = $storageName; storageAccoountKey = $accountKey1 }
# Create the Azure Functions and corresponding App Plan
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroup -TemplateFile azuredeploy.json -TemplateParameterObject $azureDeployHash

# Someone will need to create a new Azure Application object in AAD and make sure that it is certificate based
# Once this Application is created, make sure to get the below information and paste them into their correct
# variables. Please keep in mind that the Application will need at least Reader role within the Subscription
# For more information on how to do this via PowerShell, please see the following: 
# https://docs.microsoft.com/en-us/azure/automation/manage-runas-account#create-run-as-account-using-powershell
$spnAppId = "<Application Id of Service Principal>"
$spnCertThumb = "<Certificate Thumbprint or Password>"
$tenantId = "<Tenant Id of Azure Active Directory where Service Principal is Located>"
$subId = "<Subscription Id of Subscription where Automation Account is located>"

# Create all of the required Automation Objects and Shared Resources
New-AzAutomationAccount -ResourceGroupName $resourceGroup -Name $autoAccountName -Location $location
# Create the shared variable used to call the Azure Function for processing the JSON object
New-AzAutomationVariable -ResourceGroupName $resourceGroup -AutomationAccountName $autoAccountName -Encrypted $False `
    -Name OrphanFunctionURL -Value $functionOrphanURL `
    -Description "URL of the Azure Function that will populate the Storage Queue with Orphan JSON Data"
# Create the Azure RunAs Connection for actually processing Azure SDK calls
$fieldValues = @{ ApplicationId = $spnAppId; TenantId = $tenantId; SubscriptionId = $subId; CertificateThumbprint = $spnCertThumb }
New-AzAutomationConnection -ResourceGroupName $resourceGroup -AutomationAccountName $autoAccountName -Name AzureRunAsConnection -ConnectionTypeName AzureServicePrincipal -ConnectionFieldValues $fieldValues
# Import each of the PowerShell runbooks based on the current folder structure
Import-AzAutomationRunbook -ResourceGroupName $resourceGroup -AutomationAccountName $autoAccountName -Path "../ps-runbooks/audit-orphan-disks.ps1" -Type PowerShell
Import-AzAutomationRunbook -ResourceGroupName $resourceGroup -AutomationAccountName $autoAccountName -Path "../ps-runbooks/audit-orphan-publicips.ps1" -Type PowerShell
