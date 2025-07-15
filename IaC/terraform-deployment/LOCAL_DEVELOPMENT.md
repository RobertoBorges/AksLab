# Local Development Guide

This guide helps you set up and use the Terraform infrastructure locally for development and testing purposes.

## Prerequisites

### 1. Install Required Tools

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

# Install optional tools for enhanced development
# tfsec for security scanning
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# tflint for linting
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# pre-commit for git hooks
pip install pre-commit
```

### 2. Azure Authentication

```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set your subscription
az account set --subscription "your-subscription-id"

# Verify authentication
az account show
```

## Local Development Setup

### 1. Clone and Navigate

```bash
# Clone the repository
git clone https://github.com/RobertoBorges/AksLab.git
cd AksLab/IaC/terraform-deployment
```

### 2. Configure Variables

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit variables for your environment
nano terraform.tfvars
```

Example `terraform.tfvars`:
```hcl
random_seed = "dev$(whoami)01"
location    = "canadacentral"

tags = {
  Environment = "Development"
  Project     = "AKS Lab"
  ManagedBy   = "Terraform"
  Owner       = "$(whoami)"
  Purpose     = "Local Development"
}
```

### 3. Initialize and Validate

```bash
# Run validation script
./validate.sh

# Or manually:
terraform init -backend=false
terraform validate
terraform fmt -check -recursive
```

### 4. Plan and Apply

```bash
# Plan deployment
terraform plan -var-file=terraform.tfvars

# Apply deployment
terraform apply -var-file=terraform.tfvars
```

Or use the deployment script:
```bash
# Plan with deployment script
./deploy.sh -e dev -a plan

# Apply with deployment script
./deploy.sh -e dev -a apply
```

## Development Workflow

### 1. Daily Development

```bash
# Start development session
cd AksLab/IaC/terraform-deployment

# Pull latest changes
git pull origin main

# Check current state
terraform plan -var-file=terraform.tfvars

# Make changes to .tf files
# Test changes
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars
```

### 2. Testing Changes

```bash
# Test specific module
terraform plan -target=module.aks -var-file=terraform.tfvars

# Apply specific module
terraform apply -target=module.aks -var-file=terraform.tfvars

# Validate after changes
./validate.sh
```

### 3. Debugging

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Run terraform command
terraform plan -var-file=terraform.tfvars

# View logs
tail -f terraform.log
```

## Working with AKS

### 1. Connect to Cluster

```bash
# Get cluster credentials
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Test connection
kubectl get nodes
kubectl get pods -A
```

### 2. Deploy Applications

```bash
# Deploy sample application
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=LoadBalancer --port=80

# Check deployment
kubectl get services
```

### 3. Access Services

```bash
# Port forward to services
kubectl port-forward service/nginx 8080:80

# Access Grafana (if deployed)
kubectl port-forward -n monitoring service/grafana 3000:80
```

## Container Registry Usage

### 1. Login to ACR

```bash
# Get ACR name from Terraform output
ACR_NAME=$(terraform output -raw container_registry_name)

# Login to ACR
az acr login --name $ACR_NAME
```

### 2. Build and Push Images

```bash
# Build image
docker build -t $ACR_NAME.azurecr.io/myapp:latest .

# Push image
docker push $ACR_NAME.azurecr.io/myapp:latest

# Deploy to AKS
kubectl create deployment myapp --image=$ACR_NAME.azurecr.io/myapp:latest
```

## Development Best Practices

### 1. Version Control

```bash
# Install pre-commit hooks
pre-commit install

# Run hooks manually
pre-commit run --all-files

# Commit changes
git add .
git commit -m "Add new feature"
```

### 2. Code Quality

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Security scan
tfsec .

# Linting
tflint
```

### 3. State Management

```bash
# Check state
terraform state list

# Backup state
terraform state pull > terraform.tfstate.backup

# Remove resource from state
terraform state rm module.problematic_resource

# Import existing resource
terraform import module.aks.azurerm_kubernetes_cluster.aks /subscriptions/sub-id/...
```

## Environment Isolation

### 1. Using Workspaces

```bash
# Create workspace for feature development
terraform workspace new feature-branch

# Switch workspace
terraform workspace select feature-branch

# List workspaces
terraform workspace list

# Deploy to workspace
terraform apply -var-file=terraform.tfvars
```

### 2. Multiple Environments

```bash
# Development environment
terraform apply -var-file=environments/dev.tfvars

# Staging environment
cp environments/dev.tfvars environments/staging.tfvars
# Edit staging.tfvars
terraform apply -var-file=environments/staging.tfvars
```

## Cleanup

### 1. Regular Cleanup

```bash
# Destroy resources
terraform destroy -var-file=terraform.tfvars

# Or use deployment script
./deploy.sh -e dev -a destroy
```

### 2. Complete Cleanup

```bash
# Destroy all resources
terraform destroy -auto-approve -var-file=terraform.tfvars

# Clean local state
rm -rf .terraform/
rm terraform.tfstate*
rm *.tfplan

# Clean Docker images
docker system prune -a
```

## Tips and Tricks

### 1. Faster Development

```bash
# Use terraform console for testing
terraform console -var-file=terraform.tfvars

# Test expressions
> var.tags
> local.resource_group_name
```

### 2. Resource Inspection

```bash
# Show specific resource
terraform state show module.aks.azurerm_kubernetes_cluster.aks

# Get resource information
az aks show --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name)
```

### 3. Performance Optimization

```bash
# Increase parallelism
terraform apply -parallelism=20 -var-file=terraform.tfvars

# Skip refresh
terraform apply -refresh=false -var-file=terraform.tfvars
```

## IDE Integration

### 1. VS Code

Install extensions:
- HashiCorp Terraform
- Azure Account
- Kubernetes

### 2. Configuration

```json
// .vscode/settings.json
{
  "terraform.format.enable": true,
  "terraform.lint.enable": true,
  "terraform.validate.enable": true
}
```

## Common Commands Reference

```bash
# Quick development cycle
terraform init -backend=false
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# Debug issues
terraform state list
terraform state show module.aks.azurerm_kubernetes_cluster.aks
terraform output

# Cleanup
terraform destroy -var-file=terraform.tfvars
```

## Getting Help

1. Check the [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) guide
2. Review the [EXAMPLES.md](./EXAMPLES.md) for usage patterns
3. Check module documentation in `modules/*/README.md`
4. Use `terraform --help` for command help
5. Check Azure CLI help: `az aks --help`