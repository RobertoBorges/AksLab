# Azure Kubernetes Service (AKS) Deployment with Bicep

This repository contains Bicep templates for deploying an Azure Kubernetes Service (AKS) cluster along with supporting Azure resources.

## Architecture Diagram

See [architecture-diagram.md](architecture-diagram.md) for a visual representation of the deployed resources and their relationships.

## Project Structure

```
aks-deployment
└── modules/
    ├── aks.bicep           # AKS cluster configuration
    ├── appconfig.bicep     # App Configuration resource
    ├── cosmosdb.bicep      # Cosmos DB account and databases
    ├── keyvault.bicep      # Key Vault and secrets
    ├── monitoring.bicep    # Log Analytics and monitoring
    └── containerregistry.bicep  # Azure Container Registry
├── parameters/
    ├── dev.parameters.json  # Development environment parameters
    └── prod.parameters.json # Production environment parameters
├── main.bicep              # Main deployment template
└── README.md               # This file
```

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Bicep CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- Azure subscription

## Deployment

### 1. Login to Azure

```bash
az login
```

### 2. Set the subscription

```bash
az account set --subscription <subscription-id>
```

### 3. Create a resource group (if not exists)

```bash
az group create --name <resource-group-name> --location <location>
```

### 4. Deploy the Bicep template

For development environment:
```bash
az deployment group create \
  --name aks-deployment \
  --resource-group <resource-group-name> \
  --template-file main.bicep \
  --parameters @parameters/dev.parameters.json
```

For production environment:
```bash
az deployment group create \
  --name aks-deployment \
  --resource-group <resource-group-name> \
  --template-file main.bicep \
  --parameters @parameters/prod.parameters.json
```

### 5. Alternative deployment methods

#### Using direct parameter values with Azure CLI

For simpler deployments without Key Vault reference, you can use the Azure CLI to pass parameter values directly:

```bash
# Get your Azure AD Object ID (for userObjectId parameter)
$userObjectId = az ad signed-in-user show --query id -o tsv

# Deploy with direct parameter values
az deployment group create `
  --name aks-deployment `
  --resource-group <resource-group-name> `
  --template-file main.bicep `
  --parameters randomSeed=dev001 userObjectId=$userObjectId location=eastus
```

## Resources Deployed

- Azure Kubernetes Service (AKS) Deployment with Bicep
  - Architecture Diagram
  - Project Structure
  - Prerequisites
  - Deployment
    - 1. Login to Azure
    - 2. Set the subscription
    - 3. Create a resource group (if not exists)
    - 4. Deploy the Bicep template
    - 5. Alternative deployment methods
      - Using direct parameter values with Azure CLI
  - Resources Deployed
  - Configuration
    - Working with Key Vault References
  - Accessing the AKS Cluster
    - Workload Identity
  - Managing Deployed Resources
    - Connect to ACR
    - Working with Managed Identities
    - View Cosmos DB Connection Strings
  - Contributing
  - License

## Configuration

The deployment can be customized by modifying the parameter files in the `parameters` directory. Key configuration parameters include:

- `randomSeed`: String used to generate unique resource names
- `userObjectId`: The Azure AD Object ID of the user who will have admin access
- `location`: Azure region for resource deployment

### Working with Key Vault References

For sensitive parameters like `userObjectId`, you have multiple options:

1. **Development environments**: Use direct values
   ```json
   "userObjectId": {
     "value": "your-actual-object-id"
   }
   ```

2. **Production environments**: Use Key Vault references with the correct resource ID
   ```json
   "userObjectId": {
     "reference": {
       "keyVault": {
         "id": "/subscriptions/your-subscription-id/resourceGroups/your-resource-group/providers/Microsoft.KeyVault/vaults/your-key-vault-name"
       },
       "secretName": "userObjectId"
     }
   }
   ```
   Note: You must replace the placeholder values with actual subscription ID, resource group name, and key vault name.

Additional configuration options can be modified directly in the Bicep modules:

- AKS version, node pool size and count
- Network configuration and CNI settings 
- Monitoring and logging retention
- Workload identity settings

## Accessing the AKS Cluster

After deployment, get credentials to access your AKS cluster:

```bash
az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>
```

You can view the cluster's details and output values:

```bash
# Get the output values from the deployment
az deployment group show \
  --name aks-deployment \
  --resource-group <resource-group-name> \
  --query properties.outputs

# Connect to Grafana dashboard for monitoring
az grafana dashboard manage --name <grafana-name> --resource-group <resource-group-name>
```

### Workload Identity

This deployment configures workload identity for secure pod-to-Azure resource authentication. To use workload identity in your deployments:

1. Create a service account in your namespace
2. Create a federated identity credential in Azure
3. Configure your pod to use the service account with workload identity

## Managing Deployed Resources

### Connect to ACR
```bash
# Log in to the container registry
az acr login --name <acr-name>

# Build and push images
az acr build --registry <acr-name> --image myapp:latest .
```

### Working with Managed Identities
```bash
# List federated identity credentials
az identity federated-credential list --identity-name <identity-name> --resource-group <resource-group-name>

# Create new federated identity for a different service account
az identity federated-credential create \
  --name new-federated-identity \
  --identity-name <identity-name> \
  --resource-group <resource-group-name> \
  --issuer <aks-oidc-issuer-url> \
  --subject system:serviceaccount:<namespace>:<service-account-name> \
  --audience api://AzureADTokenExchange
```

### View Cosmos DB Connection Strings

```bash
# Get the Cosmos DB MongoDB connection string
az cosmosdb keys list \
  --name <mongodb-account-name> \
  --resource-group <resource-group-name> \
  --type connection-strings
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

[MIT](LICENSE)
