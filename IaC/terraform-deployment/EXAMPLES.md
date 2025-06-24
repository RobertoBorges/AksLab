# Terraform Configuration Examples

This directory contains example Terraform configurations and deployment scripts for the AKS Lab infrastructure.

## Quick Start

1. **Install Prerequisites**
   ```bash
   # Install Terraform
   wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   
   # Install Azure CLI
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

2. **Setup Azure Authentication**
   ```bash
   # Login to Azure
   az login
   
   # Set your subscription
   az account set --subscription "your-subscription-id"
   
   # Get your user object ID
   USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
   echo "Your user object ID: $USER_OBJECT_ID"
   ```

3. **Deploy Infrastructure**
   ```bash
   # Initialize Terraform
   terraform init
   
   # Plan deployment
   terraform plan -var="user_object_id=$USER_OBJECT_ID" -var="random_seed=mylab01"
   
   # Apply deployment
   terraform apply -var="user_object_id=$USER_OBJECT_ID" -var="random_seed=mylab01"
   ```

4. **Connect to AKS**
   ```bash
   # Get cluster credentials
   CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
   RESOURCE_GROUP=$(terraform output -raw resource_group_name)
   az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
   
   # Test connection
   kubectl get nodes
   ```

## Environment-Specific Deployments

### Development Environment
```bash
# Update environments/dev.tfvars with your user_object_id
terraform apply -var-file="environments/dev.tfvars"
```

### Production Environment
```bash
# Update environments/prod.tfvars with your user_object_id
terraform apply -var-file="environments/prod.tfvars"
```

## Cleanup

```bash
# Destroy all resources
terraform destroy -var="user_object_id=$USER_OBJECT_ID" -var="random_seed=mylab01"
```

## Troubleshooting

### Common Issues

1. **Authentication Error**: Ensure you're logged into Azure CLI and have set the correct subscription
2. **Permission Errors**: Verify you have Contributor access to the subscription or resource group
3. **Resource Name Conflicts**: Use a unique `random_seed` value to avoid naming conflicts

### Validation

```bash
# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt -recursive

# Check for security issues (requires tfsec)
tfsec .
```