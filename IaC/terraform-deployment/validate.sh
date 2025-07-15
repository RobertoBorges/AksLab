#!/bin/bash

# Terraform validation script
# This script validates the Terraform configuration and performs basic checks

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TERRAFORM_DIR="$SCRIPT_DIR"

echo "🔍 Validating Terraform configuration..."
echo "Working directory: $TERRAFORM_DIR"
echo ""

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

echo "✅ Terraform version: $(terraform --version | head -n1)"

# Change to Terraform directory
cd "$TERRAFORM_DIR"

# Check formatting
echo ""
echo "🔍 Checking Terraform formatting..."
if terraform fmt -check -recursive; then
    echo "✅ All files are properly formatted"
else
    echo "❌ Some files need formatting. Run 'terraform fmt -recursive' to fix."
    exit 1
fi

# Initialize without backend
echo ""
echo "🔍 Initializing Terraform..."
terraform init -backend=false > /dev/null 2>&1

# Validate configuration
echo ""
echo "🔍 Validating Terraform configuration..."
if terraform validate; then
    echo "✅ Configuration is valid"
else
    echo "❌ Configuration validation failed"
    exit 1
fi

# Check for security issues (if tfsec is available)
if command -v tfsec &> /dev/null; then
    echo ""
    echo "🔍 Running security checks with tfsec..."
    tfsec .
else
    echo ""
    echo "⚠️  tfsec not found. Install it for security scanning: https://github.com/aquasecurity/tfsec"
fi

# Check for best practices (if tflint is available)
if command -v tflint &> /dev/null; then
    echo ""
    echo "🔍 Running linting checks with tflint..."
    tflint --init > /dev/null 2>&1 || true
    tflint
else
    echo ""
    echo "⚠️  tflint not found. Install it for best practices checking: https://github.com/terraform-linters/tflint"
fi

echo ""
echo "✅ All validations completed successfully!"
echo ""
echo "Next steps:"
echo "1. Copy terraform.tfvars.example to terraform.tfvars"
echo "2. Update the variables in terraform.tfvars"
echo "3. Run 'terraform init' with backend configuration"
echo "4. Run 'terraform plan' to see what will be created"
echo "5. Run 'terraform apply' to create the infrastructure"