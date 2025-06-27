# ContosoAir - Modern Cloud-Native Demo Application

A sample airline booking application used for demos and learning purposes.

This repository is a revived and modernized version of the previously archived [microsoft/ContosoAir](https://github.com/microsoft/ContosoAir) demo project. This version has been updated with current technology standards including Node.js 22, Azure CosmosDB with MongoDB API 7.0, and modern authentication via Azure Managed Identity. While maintaining its original purpose, the codebase now features a completely refreshed infrastructure.

## Repository Organization

This project consists of two main components:

1. **Web Application (`src/`)** - The ContosoAir airline booking application built with Node.js
2. **Infrastructure (`IaC/`)** - Azure infrastructure templates to deploy the application at scale

### Quick Links:
- [Local Development Setup](#getting-started-locally) - Run the app locally
- [AKS Deployment Guide (Bicep)](IaC/aks-deployment/README.md) - Deploy to Azure Kubernetes Service using Bicep
- [AKS Deployment Guide (Terraform)](IaC/terraform-deployment/README.md) - Deploy to Azure Kubernetes Service using Terraform with GitHub Actions
- [GitHub Actions Setup Guide](docs/github-actions-setup.md) - Automated CI/CD deployment setup
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

echo "Output values:" $outputs 


# Set environment variables
$env:AZURE_COSMOS_ACCOUNT_NAME = $outputs.cosmosDbAccountName.value
$env:AZURE_COSMOS_CLIENTID = $outputs.mongoIdentityClientId.value
$env:AZURE_COSMOS_LISTCONNECTIONSTRINGURL = $outputs.mongoListConnectionStringUrl.value
$env:AZURE_COSMOS_SCOPE = "https://management.azure.com/.default"
$env:AZURE_ACR_NAME = $outputs.containerRegistryName.value
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

You have two Infrastructure as Code (IaC) options for production-grade deployment to Azure Kubernetes Service:

#### Bicep Templates
Follow the detailed guide in [IaC/aks-deployment/README.md](IaC/aks-deployment/README.md) for manual deployment using Azure Bicep templates.

#### Terraform with GitHub Actions (Automated CI/CD)
Follow the detailed guide in [IaC/terraform-deployment/README.md](IaC/terraform-deployment/README.md) for automated deployment using Terraform and GitHub Actions. This option provides:
- Automated CI/CD pipeline with GitHub Actions
- Remote state management with Azure Storage Account
- Environment-specific deployments (dev/prod)
- Security best practices with Azure service principal authentication

Both deployment options include:
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


## Define, build and modify container images

Knowing how to package your application in a container image is key to running it in Kubernetes. The most common way to do this is to use Dockerfile and Docker CLI or Podman CLI to execute image build commands.

Once the container image is built, you'll need to push it to a remote container registry. A container registry is a service that stores container images and allows you to pull them down to your local machine or to a Kubernetes cluster. There are several container registries available, with some common ones including Docker Hub or GitHub Container Registry. When using AKS, you will want to use Azure Container Registry (ACR) which is a private registry that offers several features such as geo-replication, integration with Microsoft Entra ID, artifact streaming, and even continuous vulnerability scanning and patching.

### Container image manifest with Draft

If you don't already have a container image for you application you can look to an open-source tool like Draft or lean on AI tools like GitHub Copilot to help you create a Dockerfile.

Let's look to package the Contoso Air sample application into a container image. Run the following command to clone the repository.

```bash
cd src/web
az aks draft create --dockerfile-only=true
```

This command will detect the application type is JavaScript (or Node.js) and create a Dockerfile for the application.

### Build the container image

````bash
docker build -t contoso-air:latest .

docker run -d -p 3000:3000 --name contoso-air contoso-air:latest
````

This command will run the container image and map port 3000 on the host to port 3000 in the container. You can now access the application in your browser at <http://localhost:3000/>.

### Push the container image to Azure Container Registry
```bash
# Log in to Azure Container Registry
az acr login --name $env:AZURE_ACR_NAME
# Tag the image with the ACR login server
docker tag contoso-air:latest "$($env:AZURE_ACR_NAME).azurecr.io/contoso-air:latest"
# Push the image to ACR
docker push "$($env:AZURE_ACR_NAME).azurecr.io/contoso-air:latest"
```


## Cleanup

```powershell
# Replace with your resource group name
$resourceGroup = "your-resource-group-name"

# Delete the resource group and all resources within it
az group delete --name $resourceGroup --yes --no-wait

# Display confirmation
Write-Output "Deletion of resource group '$resourceGroup' initiated. This may take several minutes to complete."
```
