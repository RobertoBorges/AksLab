#!/bin/bash

# Script to create Azure Storage Account for Terraform state
# This script should be run once to set up the infrastructure for storing Terraform state

set -e

# Default values
ENVIRONMENT="dev"
LOCATION="East US"
SUBSCRIPTION_ID=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -l|--location)
      LOCATION="$2"
      shift 2
      ;;
    -s|--subscription)
      SUBSCRIPTION_ID="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -e, --environment    Environment (dev/prod) [default: dev]"
      echo "  -l, --location       Azure location [default: East US]"
      echo "  -s, --subscription   Azure subscription ID [required]"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "Error: Subscription ID is required. Use -s or --subscription flag."
  exit 1
fi

# Generate unique suffix for storage account name
RANDOM_SUFFIX=$(openssl rand -hex 4)
RESOURCE_GROUP_NAME="rg-terraform-state-${ENVIRONMENT}"
STORAGE_ACCOUNT_NAME="tfstate${ENVIRONMENT}${RANDOM_SUFFIX}"
CONTAINER_NAME="tfstate"

echo "Creating Terraform state storage for environment: $ENVIRONMENT"
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container: $CONTAINER_NAME"
echo "Location: $LOCATION"
echo ""

# Set the subscription
echo "Setting Azure subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group
echo "Creating resource group..."
az group create \
  --name "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --tags Environment="$ENVIRONMENT" Project="AKS Lab" Purpose="Terraform State"

# Create storage account
echo "Creating storage account..."
az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags Environment="$ENVIRONMENT" Project="AKS Lab" Purpose="Terraform State"

# Create container
echo "Creating blob container..."
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --auth-mode login

echo ""
echo "✅ Terraform state storage created successfully!"
echo ""
echo "Add these values to your GitHub repository secrets:"
echo "  TF_STATE_RESOURCE_GROUP: $RESOURCE_GROUP_NAME"
echo "  TF_STATE_STORAGE_ACCOUNT: $STORAGE_ACCOUNT_NAME"
echo "  TF_STATE_CONTAINER: $CONTAINER_NAME"
echo ""
echo "Backend configuration:"
echo "  resource_group_name   = \"$RESOURCE_GROUP_NAME\""
echo "  storage_account_name  = \"$STORAGE_ACCOUNT_NAME\""
echo "  container_name        = \"$CONTAINER_NAME\""
echo "  key                   = \"${ENVIRONMENT}.terraform.tfstate\""