# ContosoAir - Modern Cloud-Native Demo Application

A sample airline booking application used for demos and learning purposes.

This repository is a revived and modernized version of the previously archived [microsoft/ContosoAir](https://github.com/microsoft/ContosoAir) demo project. This version has been updated with current technology standards including Node.js 22, Azure CosmosDB with MongoDB API 7.0, and modern authentication via Azure Managed Identity. While maintaining its original purpose, the codebase now features a completely refreshed infrastructure.

## Repository Organization

This project consists of two main components:

1. **Web Application (`src/`)** - The ContosoAir airline booking application built with Node.js
2. **Infrastructure (`IaC/`)** - Azure infrastructure templates to deploy the application at scale

### Quick Links:
- [Local Development Setup](#getting-started-locally) - Run the app locally
- [AKS Deployment Guide](IaC/aks-deployment/README.md) - Deploy to Azure Kubernetes Service
- [Architecture Diagram](IaC/aks-deployment/architecture-diagram.md) - Visual representation of the cloud architecture

## Prerequisites

- Node.js 22.0.0 or later
- Azure CLI
- POSIX-compliant shell (i.e., bash or zsh)

## Getting Started Locally

This section describes how to run the ContosoAir application locally using a basic Azure CosmosDB setup. For production deployment to AKS, see the [AKS Deployment Guide](IaC/aks-deployment/README.md).

### Development Options

You have two options for setting up the required Azure resources:

#### Option 1: Quick Local Setup with Scripts

For rapid development and testing, you can use the following PowerShell script to set up the minimum required resources:

```powershell
# Create random resource identifier
$RAND = Get-Random -Minimum 1000 -Maximum 9999
Write-Output "Random resource identifier will be: $RAND"

# Set variables
$AZURE_SUBSCRIPTION_ID = (az account show --query id -o tsv)
$AZURE_RESOURCE_GROUP_NAME = "rg-contosoair$RAND"
$AZURE_COSMOS_ACCOUNT_NAME = "db-contosoair$RAND"
$AZURE_REGION = "eastus"

# Create resource group
az group create `
  --name $AZURE_RESOURCE_GROUP_NAME `
  --location $AZURE_REGION

# Create CosmosDB account
$AZURE_COSMOS_ACCOUNT_ID = (az cosmosdb create `
  --name $AZURE_COSMOS_ACCOUNT_NAME `
  --resource-group $AZURE_RESOURCE_GROUP_NAME `
  --kind MongoDB `
  --server-version 7.0 `
  --query id -o tsv)

# Create test database
az cosmosdb mongodb database create `
  --account-name $AZURE_COSMOS_ACCOUNT_NAME `
  --resource-group $AZURE_RESOURCE_GROUP_NAME `
  --name test

# Create managed identity
$AZURE_COSMOS_IDENTITY_ID = (az identity create `
  --name "db-contosoair$RAND-id" `
  --resource-group $AZURE_RESOURCE_GROUP_NAME `
  --query id -o tsv)

# Get managed identity principal ID
$AZURE_COSMOS_IDENTITY_PRINCIPAL_ID = (az identity show `
  --ids $AZURE_COSMOS_IDENTITY_ID `
  --query principalId -o tsv)

# Assign role to managed identity
az role assignment create `
  --role "DocumentDB Account Contributor" `
  --assignee $AZURE_COSMOS_IDENTITY_PRINCIPAL_ID `
  --scope $AZURE_COSMOS_ACCOUNT_ID

# Set environment variables for azure identity auth
$env:AZURE_COSMOS_CLIENTID = (az identity show --ids $AZURE_COSMOS_IDENTITY_ID --query clientId -o tsv)
$env:AZURE_COSMOS_LISTCONNECTIONSTRINGURL = "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP_NAME/providers/Microsoft.DocumentDB/databaseAccounts/$AZURE_COSMOS_ACCOUNT_NAME/listConnectionStrings?api-version=2021-04-15"
$env:AZURE_COSMOS_SCOPE = "https://management.azure.com/.default"

# Display environment variables that need to be set
Write-Output "Environment variables set for this session. For persistence across sessions, add these to your environment:"
Write-Output "AZURE_COSMOS_CLIENTID = $env:AZURE_COSMOS_CLIENTID"
Write-Output "AZURE_COSMOS_LISTCONNECTIONSTRINGURL = $env:AZURE_COSMOS_LISTCONNECTIONSTRINGURL" 
Write-Output "AZURE_COSMOS_SCOPE = $env:AZURE_COSMOS_SCOPE"
```

#### Option 2: Infrastructure as Code (Recommended)

For a more reproducible and production-like setup, use the Bicep templates in the `IaC/aks-deployment` directory:

```powershell
# Navigate to the IaC directory
cd IaC/aks-deployment

# Get your Azure AD Object ID for the Key Vault access
$userObjectId = (az ad signed-in-user show --query id -o tsv)

# Deploy development environment
az deployment group create `
  --name dev-deployment `
  --resource-group <your-resource-group-name> `
  --template-file main.bicep `
  --parameters randomSeed=dev001 userObjectId=$userObjectId location=eastus
```

After deployment, extract the required connection information from the output:

```powershell
# Get the deployment outputs
$outputs = (az deployment group show `
  --name dev-deployment `
  --resource-group <your-resource-group-name> `
  --query properties.outputs -o json | ConvertFrom-Json)

# Set environment variables
$env:AZURE_COSMOS_ACCOUNT_NAME = $outputs.cosmosDbAccountName.value
$env:AZURE_COSMOS_CLIENTID = $outputs.mongoIdentityClientId.value
$env:AZURE_COSMOS_LISTCONNECTIONSTRINGURL = $outputs.mongoListConnectionStringUrl.value
$env:AZURE_COSMOS_SCOPE = "https://management.azure.com/.default"
```

### Run the Application Locally

With the Azure resources provisioned and environment variables set (using either Option 1 or 2), start the application:

```powershell
# Navigate to the web application directory
cd src/web

# Install dependencies
npm install

# Run the application
npm start
```

Browse to `http://localhost:3000` to see the app running.

## Deployment Options

### Option 1: Local Development

For local development and testing, use the [Getting Started Locally](#getting-started-locally) instructions above with either the quick setup script or the development Bicep deployment.

### Option 2: AKS Deployment (Recommended for Production)

For production-grade deployment to Azure Kubernetes Service, follow the detailed guide in [IaC/aks-deployment/README.md](IaC/aks-deployment/README.md).

The AKS deployment includes:
- Azure Kubernetes Service with modern features:
  - Workload Identity integration
  - Azure CNI Overlay networking with Cilium
  - KEDA and Vertical Pod Autoscaler
  - Azure Key Vault CSI Provider
  - Web Application Routing add-on
- Azure Container Registry with AKS pull access
- Azure Key Vault for secrets management with RBAC authorization
- Azure Cosmos DB MongoDB API (configured for production)
- Azure App Configuration for feature flags and settings
- Comprehensive monitoring with Azure Monitor, Prometheus, and Grafana

See the [architecture diagram](IaC/aks-deployment/architecture-diagram.md) for a visual representation of this deployment.

## Cleanup

```powershell
# Replace with your resource group name
$resourceGroup = "your-resource-group-name"

# Delete the resource group and all resources within it
az group delete --name $resourceGroup --yes --no-wait

# Display confirmation
Write-Output "Deletion of resource group '$resourceGroup' initiated. This may take several minutes to complete."
```
