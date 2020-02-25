# Please keep in mind that this script was put together with the intent that it would be run
# inside of Azure Cloud Shell, therefore all Authentication has been kept out of the script.

$location = "<Region Specification>"
$resourceGroup = "<Name of Resource Group>"
$autoAccountName = "<Name of Automation Account>"
$storageName = "azureorphanfuncstor"
$functionAppName = "<Name of Function App>"
$functionAppPlanName = "<Name for the App Service Plan associated with FunctionApp>"
$functionOrphanURL = "https://" + $functionAppName + ".azurewebsites.net/api/AzureOrphanHttpTrigger"

$azureDeployHash = @{ location = $location; functionAppServicePlan = $functionAppPlanName; functionAppName = $functionAppName }
# Create the Azure Functions and corresponding App Plan
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup `
    -TemplateFile azuredeploy.json -TemplateParameterObject $azureDeployHash

# Someone will need to create a new Azure Application object in AAD and make sure that it is certificate based
# Once this Application is created, make sure to get the below information and paste them into their correct
# variables. Please keep in mind that the Application will need at least Reader role within the Subscription
$spnAppId = ""
$spnCertThumb = ""
$tenantId = ""
$subId = ""

# Create all of the required Automation Objects and Shared Resources
New-AzureRmAutomationAccount -ResourceGroupName $resourceGroup -Name $autoAccountName -Location $location
# Create the shared variable used to call the Azure Function for processing the JSON object
New-AzureRmAutomationVariable -ResourceGroupName $resourceGroup -AutomationAccountName $autoAccountName `
    -Name OrphanFunctionURL -Value $functionOrphanURL `
    -Description "URL of the Azure Function that will populate the Storage Queue with Orphan JSON Data"
# Create the Azure RunAs Connection for actually processing Azure SDK calls
$fieldValues = @{ ApplicationId = $spnAppId; TenantId = $tenantId; SubscriptionId = $subsId; CertificateThumbprint = $spnCertThumb }
New-AzureRmAutomationConnection -ResourceGroupName $resourceGroup -AutomationAccountName -$autoAccountName -Name AzureRunAsConnection -ConnectionTypeName AzureServicePrincipal -ConnectionFieldValues $fieldValues
# Import each of the PowerShell runbooks based on the current folder structure


$storageAcct = New-AzStorageAccount -ResourceGroupName $resourceGroup -Location $location `
    -Name $storageName -AccessTier Hot -Kind StorageV2 -SkuName Standard_LRS
$ctx = $storageAcct.Context
New-AzStorageQueue -Name orphans -Context $ctx
New-AzStorageQueue -Name auditreports -Context $ctx
