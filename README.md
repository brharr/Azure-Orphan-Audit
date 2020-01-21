Thank you for checking out this repository. This repository contains all the pieces necessary to deploy into your Azure Subscription and then get periodic emails about any
orphaned resources that may be using up limits or costing you money. 

### NOTE 
This particular solution is based on a single subscription auditing process, but it would not take a lot of effort to make this work across multiple subscriptions.
A simple modification would need to be added to each of the Runbooks to change the subscription context to make this happen.

The resoruces required are the following:

1. Azure Automation Runbooks
2. Azure Function App (Consumption)
3. Azure Storage Queue
4. Azure Logic App

## Installation

