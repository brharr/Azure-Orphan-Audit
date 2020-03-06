Thank you for checking out this repository. This repository contains all the pieces necessary to deploy into your Azure Subscription and then get periodic emails about any
orphaned resources that may be using up limits or costing you money. 

**NOTE** This particular solution is based on a single subscription auditing process, but it would not take a lot of effort to make this work across multiple subscriptions.
A simple modification would need to be added to each of the Runbooks to change the subscription context to make this happen.

The resoruces required are the following:

1. Azure Automation Runbooks
2. Azure Function App (Consumption)
3. Azure Storage Queue
4. Azure Logic App

## Installation

### Automated
Following is a set of steps to install the solution using the "install-solution.ps1" which can be found in the install folder. This set of steps assumes that you will be cloning the repository to your Azure CloudShell storage account before starting, but you can also run it locally as well, but you will of course be required to Authenticate to Azure first. 

1. Login and Authenticate to your Azure subscription. Open CloudShell and then clone this repository to the folder of your choice. 

2. Change Directory to the Install Folder

3. Edit the install-solution.ps1 and enter in correct values for each of the required parameters including the ones required for the Service Principal

4. Run the install-solution.ps1 script either as a whole or by copying and pasting the specific sections

5. Create two new NodeJS based functions using the code found in the AzureOrphanHttpTrigger and CreateOrphanEmailContentTimer folders and package.json [Http](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function) & [Timer](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-scheduled-function#create-a-timer-triggered-function)

6. Add an Output Integration to the Http Trigger to connect to the "orphans" queue within the Storage Account. Use the Storage Account connection string to add it manually or use the Portal UI to add it through the Integrate tab of the Function [Docs](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-storage-queue-output?tabs=csharp)

7. Update all existing modules within the Automation Account [Docs](https://docs.microsoft.com/en-us/azure/automation/automation-update-azure-modules)

8. Using the Browse Gallery function within the Automation Account, add the AzureRm.Network module to the Shared Modules section [Docs](https://docs.microsoft.com/en-us/azure/automation/shared-resources/modules)

9. Using the logicapp.json file within the "install" folder, create a new Azure Logic App. Once created, configure the trigger to point to the Azure Storage Account and "auditreports" queue created in Step 1 and configure SendEmailv2 step using your Office 365 subscription or modify to fit your business


### Manual
Following are the steps necessary to setup the solution within your subscription using the Azure Portal. A more automated solution will be made available in the coming weeks. For each step, I have provided a link to the documentation within Azure docs should you need it.

1. Create a new Azure Storage Account and add two new Queues within the Account, one called "orphans" and "auditreports" [Docs](https://docs.microsoft.com/en-us/azure/storage/queues/storage-quickstart-queues-portal)

2. Create new Azure Function App [Docs](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-function-app-portal)

3. Create two new NodeJS based functions using the code found in the AzureOrphanHttpTrigger and CreateOrphanEmailContentTimer folders and package.json [Http](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function) & [Timer](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-scheduled-function#create-a-timer-triggered-function)

4. Add an Output Integration to the Http Trigger to connect to the "orphans" queue within the Storage Account mentioned in Step 1. Use the Storage Account connection string to add it manually or use the Portal UI to add it through the Integrate tab of the Function [Docs](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-storage-queue-output?tabs=csharp)

5. Create new Azure Automation Account [Docs](https://docs.microsoft.com/en-us/azure/automation/automation-quickstart-create-account)
**NOTE** Make sure that the AzureRunAsAccount is created automatically during creation of the Automation Account or that you create a manual Service Principal and add a Shared Connection object within the Automation Account [Docs](https://docs.microsoft.com/en-us/azure/automation/automation-connections#creating-a-new-connection)

6. Grab the Azure Function URL for the Http Trigger based Function and create a new Automation Variable called "OrphanFunctionURL" [Docs](https://docs.microsoft.com/en-us/azure/automation/shared-resources/variables)

7. Update all existing modules within the Automation Account [Docs](https://docs.microsoft.com/en-us/azure/automation/automation-update-azure-modules)

8. Using the Browse Gallery function, add the AzureRm.Network module to the Shared Modules section [Docs](https://docs.microsoft.com/en-us/azure/automation/shared-resources/modules)

9. Import each of the Runbooks found within the ps-runbooks folder into the Automation Account and Publish them for use [Docs](https://docs.microsoft.com/en-us/azure/automation/manage-runbooks#import-a-runbook)

10. Using the logicapp.json file within the "install" folder, create a new Azure Logic App. Once created, configure the trigger to point to the Azure Storage Account and "auditreports" queue created in Step 1 and configure SendEmailv2 step using your Office 365 subscription or modify to fit your business

I did a manual walkthrough of this process during my Twitch stream and that can still be found at the following URLs:

- [Part1](https://www.twitch.tv/videos/550542215)
- [Part2](https://www.twitch.tv/videos/552042323)
