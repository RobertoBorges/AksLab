# Azure Kubernetes Service (AKS) Deployment with Terraform

This directory contains Terraform templates for deploying an Azure Kubernetes Service (AKS) cluster along with supporting Azure resources. This is a Terraform equivalent of the Bicep templates in the `../aks-deployment` directory.

## Architecture Diagram

See [../aks-deployment/architecture-diagram.md](../aks-deployment/architecture-diagram.md) for a visual representation of the deployed resources and their relationships.

## Project Structure

```
terraform-deployment/
├── modules/
│   ├── aks/                    # AKS cluster configuration
│   ├── app_configuration/      # App Configuration resource
│   ├── cosmos_db/             # Cosmos DB account and databases
│   ├── key_vault/             # Key Vault and secrets
│   ├── monitoring/            # Log Analytics and monitoring
│   └── container_registry/    # Azure Container Registry
├── environments/
│   ├── dev.tfvars             # Development environment variables
│   └── prod.tfvars            # Production environment variables
├── main.tf                    # Main deployment configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── providers.tf               # Provider configuration
├── versions.tf                # Version constraints
└── README.md                  # This file
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
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

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan the deployment

For development environment:
```bash
terraform plan -var-file="environments/dev.tfvars"
```

For production environment:
```bash
terraform plan -var-file="environments/prod.tfvars"
```

### 5. Deploy the infrastructure

For development environment:
```bash
terraform apply -var-file="environments/dev.tfvars"
```

For production environment:
```bash
terraform apply -var-file="environments/prod.tfvars"
```

### 6. Alternative deployment with inline variables

```bash
# Get your Azure AD Object ID (for user_object_id variable)
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# Deploy with inline variables
terraform apply \
  -var="random_seed=dev001" \
  -var="user_object_id=$USER_OBJECT_ID" \
  -var="location=eastus"
```

## Resources Deployed

- **Azure Kubernetes Service (AKS)**
  - Advanced networking with Azure CNI and Cilium
  - Workload Identity enabled
  - KEDA and Vertical Pod Autoscaler
  - Web Application Routing add-on
- **Azure Container Registry (ACR)** with AKS pull permissions
- **Azure Key Vault** with RBAC authorization and workload identity
- **Azure Cosmos DB** with MongoDB API (serverless)
- **Azure App Configuration** with Kubernetes provider extension
- **Azure Monitor stack** (Log Analytics, Prometheus, Grafana)

## Configuration

The deployment can be customized by modifying the variable files in the `environments` directory or by providing variables inline. Key configuration parameters include:

- `random_seed`: String used to generate unique resource names
- `user_object_id`: The Azure AD Object ID of the user who will have admin access
- `location`: Azure region for resource deployment

## Accessing the AKS Cluster

After deployment, get credentials to access your AKS cluster:

```bash
# Get the cluster name from Terraform output
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Get credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

### Workload Identity

This deployment configures workload identity for secure pod-to-Azure resource authentication. The following managed identities are created with federated credentials:

- MongoDB identity for Cosmos DB access
- Key Vault identity for secret access  
- App Configuration identity for configuration access

## Managing Deployed Resources

### Connect to ACR
```bash
# Get ACR name from Terraform output
ACR_NAME=$(terraform output -raw container_registry_name)

# Log in to the container registry
az acr login --name $ACR_NAME
```

### View Terraform State
```bash
# List all resources in state
terraform state list

# Show specific resource details
terraform state show module.aks.azurerm_kubernetes_cluster.aks
```

### Destroy Resources
```bash
# Destroy all resources
terraform destroy -var-file="environments/dev.tfvars"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

[MIT](../../LICENSE.md)