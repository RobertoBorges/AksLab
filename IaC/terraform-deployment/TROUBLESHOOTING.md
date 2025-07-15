# Troubleshooting Guide

This guide helps you diagnose and resolve common issues when deploying the AKS Lab infrastructure with Terraform.

## Prerequisites Check

### 1. Terraform Installation

```bash
# Check Terraform version
terraform --version

# Should be >= 1.0
# If not installed:
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 2. Azure CLI Installation

```bash
# Check Azure CLI version
az --version

# Should be >= 2.0
# If not installed:
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 3. Azure Authentication

```bash
# Check if logged in
az account show

# If not logged in:
az login

# Set correct subscription
az account set --subscription "your-subscription-id"
```

## Common Issues and Solutions

### 1. Authentication Errors

#### Issue: `Error: building AzureRM Client: obtain subscription() from Azure CLI: Error parsing json result from the Azure CLI`

**Solution:**
```bash
# Clear Azure CLI cache
az account clear
az login

# Set subscription explicitly
az account set --subscription "your-subscription-id"

# Verify authentication
az account show
```

#### Issue: `Error: retrieving role assignments: getting tenant ID: getting multi-tenant config: getting token: GetTokenRequest: authenticating`

**Solution:**
```bash
# Clear tokens and re-authenticate
az account clear
az login --tenant your-tenant-id

# Set environment variables for service principal (if using)
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
```

### 2. Permission Errors

#### Issue: `Error: authorization failed: the client does not have authorization to perform action`

**Solution:**
```bash
# Check your role assignments
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)

# You need at least "Contributor" role
az role assignment create \
  --role "Contributor" \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --scope "/subscriptions/your-subscription-id"
```

#### Issue: `Error: Provider does not have required permissions`

**Solution:**
```bash
# Register required resource providers
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.DocumentDB
az provider register --namespace Microsoft.AppConfiguration
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.OperationalInsights

# Check registration status
az provider show --namespace Microsoft.ContainerService --query registrationState
```

### 3. Resource Name Conflicts

#### Issue: `Error: resource with the name "xyz" already exists`

**Solution:**
```bash
# Use a unique random_seed
terraform apply -var="random_seed=$(date +%s)"

# Or update your variables file
echo 'random_seed = "unique-id-'$(date +%s)'"' >> terraform.tfvars
```

#### Issue: `Error: storage account name "xyz" is already taken`

**Solution:**
```bash
# Storage account names must be globally unique
# Use a longer random seed or include more entropy
terraform apply -var="random_seed=$(openssl rand -hex 4)"
```

### 4. Backend State Issues

#### Issue: `Error: Error locking state: Error acquiring the state lock`

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Or wait for the lock to expire (usually 15 minutes)
```

#### Issue: `Error: Backend configuration changed`

**Solution:**
```bash
# Reinitialize backend
terraform init -reconfigure

# Or migrate to new backend
terraform init -migrate-state
```

### 5. Network and Quota Issues

#### Issue: `Error: exceeded quota limits`

**Solution:**
```bash
# Check current quotas
az vm list-usage --location canadacentral --output table

# Request quota increase
az support tickets create \
  --type "QuotaAndUsage" \
  --severity "low" \
  --description "Need quota increase for AKS deployment"
```

#### Issue: `Error: subnet is not valid in Virtual Network`

**Solution:**
```bash
# Check existing VNets and subnets
az network vnet list --resource-group your-rg

# Ensure IP ranges don't overlap
# Default AKS uses 10.0.0.0/16 for service CIDR
```

### 6. Module and Configuration Issues

#### Issue: `Error: Module not found`

**Solution:**
```bash
# Run terraform init to download modules
terraform init

# Or force module upgrade
terraform init -upgrade
```

#### Issue: `Error: Invalid for_each argument`

**Solution:**
```bash
# Check variable types and ensure they're properly formatted
terraform console
> var.tags
```

### 7. Kubernetes/AKS Specific Issues

#### Issue: `Error: waiting for create of AKS Cluster: code="VMSizeNotSupported"`

**Solution:**
```bash
# Check available VM sizes in your region
az vm list-sizes --location canadacentral --output table

# Update node pool VM size in variables
terraform apply -var="node_vm_size=Standard_D2s_v3"
```

#### Issue: `Error: AKS cluster identity cannot be changed`

**Solution:**
```bash
# This requires cluster recreation
terraform destroy -target=module.aks
terraform apply
```

## Validation and Testing

### 1. Configuration Validation

```bash
# Run validation script
./validate.sh

# Manual validation
terraform validate
terraform fmt -check -recursive
terraform plan -detailed-exitcode
```

### 2. Security Scanning

```bash
# Install tfsec
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Run security scan
tfsec .

# Fix common issues
tfsec . --soft-fail
```

### 3. Connectivity Testing

```bash
# Test AKS cluster connectivity
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
kubectl get nodes
kubectl get pods -A
```

## Debugging Techniques

### 1. Enable Debug Logging

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Run terraform command
terraform apply -var-file="environments/dev.tfvars"

# View logs
tail -f terraform.log
```

### 2. Azure CLI Debug

```bash
# Enable Azure CLI debug
az --debug account show

# Check Azure CLI configuration
az configure --list-defaults
```

### 3. State Inspection

```bash
# List all resources in state
terraform state list

# Show resource details
terraform state show module.aks.azurerm_kubernetes_cluster.aks

# Remove corrupted resources from state
terraform state rm module.problematic_resource
```

### 4. Plan Analysis

```bash
# Generate detailed plan
terraform plan -out=debug.tfplan -detailed-exitcode

# Analyze plan
terraform show debug.tfplan
terraform show -json debug.tfplan | jq '.'
```

## Recovery Procedures

### 1. State Recovery

```bash
# Backup current state
terraform state pull > terraform.tfstate.backup

# Import existing resources
terraform import module.aks.azurerm_kubernetes_cluster.aks /subscriptions/sub-id/resourceGroups/rg-name/providers/Microsoft.ContainerService/managedClusters/cluster-name

# Restore from backup
terraform state push terraform.tfstate.backup
```

### 2. Partial Deployment Recovery

```bash
# Deploy only specific modules
terraform apply -target=module.monitoring
terraform apply -target=module.aks
terraform apply -target=module.cosmos_db
```

### 3. Clean Slate Recovery

```bash
# Destroy everything
terraform destroy -auto-approve

# Remove state files
rm -rf .terraform/
rm terraform.tfstate*

# Start fresh
terraform init
terraform apply
```

## Performance Optimization

### 1. Parallel Execution

```bash
# Increase parallelism
terraform apply -parallelism=20
```

### 2. Resource Targeting

```bash
# Apply only changed resources
terraform apply -target=module.aks
```

### 3. Refresh Optimization

```bash
# Skip refresh for large states
terraform apply -refresh=false
```

## Support and Resources

### 1. Log Collection

```bash
# Collect all relevant logs
mkdir -p debug-logs
terraform show > debug-logs/terraform-show.txt
terraform state list > debug-logs/terraform-state.txt
az account show > debug-logs/azure-account.txt
kubectl get nodes -o yaml > debug-logs/kubernetes-nodes.yaml
```

### 2. Community Resources

- [Terraform AzureRM Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Community Forum](https://discuss.hashicorp.com/c/terraform-providers/tf-azurerm/)

### 3. Issue Reporting

When reporting issues, include:
- Terraform version
- Azure CLI version
- Error messages
- Terraform configuration
- Azure subscription details
- Steps to reproduce

```bash
# Generate diagnostic information
terraform version
az --version
terraform validate
terraform plan -no-color 2>&1 | head -100
```