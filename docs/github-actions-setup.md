# GitHub Actions Setup Guide

This guide walks you through setting up GitHub Actions for automated Terraform deployment of the AKS Lab infrastructure.

## Prerequisites

- Azure CLI installed and configured
- GitHub repository with administrative access
- Azure subscription with Contributor permissions

## Step 1: Create Azure Service Principal

Create a service principal that GitHub Actions will use to authenticate with Azure:

```bash
# Replace <subscription-id> with your actual subscription ID
SUBSCRIPTION_ID="<your-subscription-id>"

# Create service principal with contributor role
az ad sp create-for-rbac \
  --name "terraform-github-actions-akslab" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth
```

**Important**: Save the JSON output - you'll need it for GitHub secrets.

## Step 2: Set Up Terraform State Storage

Run the provided script to create Azure Storage Accounts for Terraform state:

```bash
# Make the script executable
chmod +x scripts/setup-terraform-backend.sh

# Create storage for development environment
./scripts/setup-terraform-backend.sh -e dev -s $SUBSCRIPTION_ID

# Create storage for production environment  
./scripts/setup-terraform-backend.sh -e prod -s $SUBSCRIPTION_ID
```

The script will output the values you need for GitHub secrets.

## Step 4: Configure GitHub Secrets

Go to your GitHub repository and navigate to `Settings > Secrets and variables > Actions`.

Create the following **Repository secrets**:

| Secret Name | Description | Example Value |
|------------|-------------|---------------|
| `AZURE_CREDENTIALS` | JSON output from service principal creation | `{"clientId": "xxx", "clientSecret": "xxx", ...}` |
| `TF_STATE_RESOURCE_GROUP` | Resource group for Terraform state | `rg-terraform-state-dev` |
| `TF_STATE_STORAGE_ACCOUNT` | Storage account for Terraform state | `tfstatedev12345678` |
| `TF_STATE_CONTAINER` | Container name for state files | `tfstate` |

### Setting up Environment-specific Secrets

If you need different configurations for dev and prod environments, you can create **Environment secrets**:

1. Go to `Settings > Environments`
2. Create environments: `dev` and `prod`
3. Add environment-specific secrets with the same names as above

## Step 5: Test the Workflow

1. Create a new branch and make a change to any file in `IaC/terraform-deployment/`
2. Create a pull request - this should trigger a `terraform plan`
3. Merge to `develop` branch - this should trigger deployment to dev environment
4. Merge to `main` branch - this should trigger deployment to prod environment

## Step 6: Manual Workflow Execution

You can also trigger deployments manually:

1. Go to `Actions` tab in your GitHub repository
2. Select `Deploy Terraform Infrastructure` workflow
3. Click `Run workflow`
4. Choose environment (dev/prod) and action (plan/apply/destroy)

## Troubleshooting

### Common Issues

1. **Authentication Failed**: Verify your `AZURE_CREDENTIALS` secret is valid
2. **State Storage Access Denied**: Ensure the service principal has access to the storage account

### Checking Workflow Logs

1. Navigate to the `Actions` tab in your repository
2. Click on the failed workflow run
3. Expand the failed job to see detailed logs
4. Look for specific error messages in the Terraform steps

### Re-creating Service Principal

If you need to recreate the service principal:

```bash
# Delete existing service principal
az ad sp delete --id <client-id-from-credentials>

# Create new one
az ad sp create-for-rbac \
  --name "terraform-github-actions-akslab" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth
```

## Security Best Practices

1. **Limit Service Principal Permissions**: Only grant the minimum required permissions
2. **Use Environment Protection Rules**: Set up environment protection rules for production
3. **Regular Credential Rotation**: Rotate service principal credentials regularly
4. **Monitor Activity**: Review GitHub Actions logs and Azure activity logs regularly

## Next Steps

After successful setup:

1. Review the deployed resources in the Azure portal
2. Configure additional environment-specific variables as needed
3. Set up monitoring and alerting for your infrastructure
4. Consider implementing additional approval workflows for production deployments
