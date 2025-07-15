# Terraform Configuration Examples

This directory contains example Terraform configurations and deployment scripts for the AKS Lab infrastructure.

## Quick Start

### 1. Install Prerequisites

```bash
# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 2. Setup Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Verify access
az account show
```

### 3. Configure Variables

```bash
# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit variables (update random_seed to be unique)
nano terraform.tfvars
```

### 4. Deploy Infrastructure

#### Option A: Using the deployment script (Recommended)

```bash
# Make script executable
chmod +x deploy.sh

# Plan deployment
./deploy.sh -e dev -a plan

# Apply deployment  
./deploy.sh -e dev -a apply

# Non-interactive deployment
./deploy.sh -e dev -a apply -y
```

#### Option B: Manual deployment

```bash
# Initialize Terraform
terraform init -backend=false

# Plan deployment
terraform plan -var-file="environments/dev.tfvars"

# Apply deployment
terraform apply -var-file="environments/dev.tfvars"
```

### 5. Connect to AKS

```bash
# Get cluster credentials
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Test connection
kubectl get nodes
kubectl get pods -A
```

## Environment-Specific Deployments

### Development Environment

```bash
# Using deployment script
./deploy.sh -e dev -a plan
./deploy.sh -e dev -a apply

# Manual deployment
terraform apply -var-file="environments/dev.tfvars"
```

### Production Environment

```bash
# Using deployment script
./deploy.sh -e prod -a plan
./deploy.sh -e prod -a apply

# Manual deployment
terraform apply -var-file="environments/prod.tfvars"
```

### Custom Environment

```bash
# Create custom variables file
cp environments/dev.tfvars environments/staging.tfvars

# Edit the file
nano environments/staging.tfvars

# Deploy with custom variables
terraform apply -var-file="environments/staging.tfvars"
```

## Advanced Examples

### 1. Deploy with Inline Variables

```bash
terraform apply \
  -var="random_seed=mylab01" \
  -var="location=eastus" \
  -var='tags={"Environment"="Development","Owner"="MyTeam"}'
```

### 2. Deploy with Custom Resource Group

```bash
# Create resource group first
az group create --name my-existing-rg --location canadacentral

# Deploy into existing resource group
terraform apply \
  -var="random_seed=mylab01" \
  -var="resource_group_name=my-existing-rg"
```

### 3. Deploy to Multiple Regions

```bash
# Deploy to Canada Central
terraform apply -var="random_seed=lab01" -var="location=canadacentral"

# Deploy to East US (different workspace)
terraform workspace new eastus
terraform apply -var="random_seed=lab02" -var="location=eastus"
```

### 4. Selective Resource Deployment

```bash
# Deploy only monitoring resources
terraform apply -target=module.monitoring -var-file="environments/dev.tfvars"

# Deploy only AKS cluster
terraform apply -target=module.aks -var-file="environments/dev.tfvars"
```

## Backend Configuration Examples

### 1. Using Azure Storage Backend

```bash
# Create backend storage first
../scripts/setup-terraform-backend.sh -e dev -s your-subscription-id

# Initialize with backend
terraform init \
  -backend-config="resource_group_name=rg-terraform-state-dev" \
  -backend-config="storage_account_name=tfstatedev12345678" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.terraform.tfstate"
```

### 2. Using Backend Configuration File

```bash
# Create backend configuration file
cat > backend.hcl << EOF
resource_group_name   = "rg-terraform-state-dev"
storage_account_name  = "tfstatedev12345678"
container_name        = "tfstate"
key                   = "dev.terraform.tfstate"
EOF

# Initialize with config file
terraform init -backend-config=backend.hcl
```

### 3. Environment-Specific Backend

```bash
# Development backend
terraform init -backend-config="backend-configs/dev.hcl"

# Production backend
terraform init -backend-config="backend-configs/prod.hcl"
```

## Validation and Testing

### 1. Validate Configuration

```bash
# Run validation script
./validate.sh

# Manual validation
terraform validate
terraform fmt -check -recursive
```

### 2. Plan Analysis

```bash
# Create and save plan
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan

# Analyze plan
terraform show dev.tfplan
terraform show -json dev.tfplan | jq '.resource_changes[].change.actions'
```

### 3. Security Scanning

```bash
# Install tfsec
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Run security scan
tfsec .

# Run with specific checks
tfsec . --check=azure-keyvault-key-expiration
```

## Output Examples

### 1. Get All Outputs

```bash
# Show all outputs
terraform output

# Get specific output
terraform output -raw aks_cluster_name
terraform output -raw container_registry_name
```

### 2. Use Outputs in Scripts

```bash
#!/bin/bash
# Example script using Terraform outputs

CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
ACR_NAME=$(terraform output -raw container_registry_name)

echo "Cluster: $CLUSTER_NAME"
echo "Resource Group: $RESOURCE_GROUP"
echo "Container Registry: $ACR_NAME"

# Configure kubectl
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Configure docker for ACR
az acr login --name $ACR_NAME
```

### 3. Export Outputs to Environment Variables

```bash
# Export all outputs as environment variables
eval $(terraform output -json | jq -r 'to_entries[] | "export TF_\(.key | ascii_upcase)=\(.value.value)"')

# Use the exported variables
echo "AKS Cluster: $TF_AKS_CLUSTER_NAME"
echo "Resource Group: $TF_RESOURCE_GROUP_NAME"
```

## Cleanup

### 1. Destroy Infrastructure

```bash
# Using deployment script
./deploy.sh -e dev -a destroy

# Non-interactive destroy
./deploy.sh -e dev -a destroy -y

# Manual destroy
terraform destroy -var-file="environments/dev.tfvars"
```

### 2. Selective Cleanup

```bash
# Remove specific resources
terraform destroy -target=module.cosmos_db -var-file="environments/dev.tfvars"

# Remove multiple resources
terraform destroy \
  -target=module.cosmos_db \
  -target=module.key_vault \
  -var-file="environments/dev.tfvars"
```

### 3. Clean State

```bash
# Remove from state without destroying
terraform state rm module.cosmos_db

# List state resources
terraform state list

# Show state resource details
terraform state show module.aks.azurerm_kubernetes_cluster.aks
```

## Troubleshooting

### Common Issues

1. **Authentication Error**
   ```bash
   # Ensure you're logged into Azure CLI
   az login
   az account show
   
   # Check your permissions
   az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)
   ```

2. **Permission Errors**
   ```bash
   # Verify subscription access
   az account list-locations
   
   # Check resource provider registration
   az provider show --namespace Microsoft.ContainerService
   az provider register --namespace Microsoft.ContainerService
   ```

3. **Resource Name Conflicts**
   ```bash
   # Use unique random_seed
   terraform apply -var="random_seed=$(date +%s)"
   
   # Check existing resources
   az resource list --resource-group rg-akslab-dev001
   ```

4. **Backend State Issues**
   ```bash
   # Force unlock state
   terraform force-unlock LOCK_ID
   
   # Import existing resource
   terraform import module.aks.azurerm_kubernetes_cluster.aks /subscriptions/sub-id/resourceGroups/rg-name/providers/Microsoft.ContainerService/managedClusters/cluster-name
   ```

### Validation

```bash
# Run comprehensive validation
./validate.sh

# Manual validation steps
terraform validate
terraform fmt -check -recursive
terraform plan -detailed-exitcode

# Check for security issues (requires tfsec)
tfsec .

# Check for best practices (requires tflint)
tflint
```

### Debug Mode

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
terraform apply -var-file="environments/dev.tfvars"

# View logs
tail -f terraform.log
```

### Resource Inspection

```bash
# List all resources
terraform state list

# Show resource details
terraform state show module.aks.azurerm_kubernetes_cluster.aks

# Get resource information from Azure
az aks show --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name)
```

## Integration Examples

### 1. CI/CD Pipeline Usage

```yaml
# Example GitHub Actions step
- name: Deploy Infrastructure
  run: |
    cd IaC/terraform-deployment
    ./deploy.sh -e ${{ github.event.inputs.environment }} -a apply -y
```

### 2. Application Deployment

```bash
# After infrastructure is deployed
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
ACR_NAME=$(terraform output -raw container_registry_name)

# Configure kubectl
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Deploy application
kubectl apply -f ../../../src/k8s/
```

### 3. Monitoring Setup

```bash
# Connect to Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# View logs
kubectl logs -n kube-system -l app=kubernetes-dashboard
```

## Best Practices

1. **Always use version control** for your Terraform configurations
2. **Use remote state** for team collaboration
3. **Implement proper tagging** for resource organization
4. **Use variables and modules** for reusability
5. **Test in development** before production deployment
6. **Monitor resources** and set up alerts
7. **Document your infrastructure** and deployment processes
8. **Use least privilege** for service accounts and permissions
9. **Regular security scans** of your infrastructure code
10. **Backup important data** and state files
