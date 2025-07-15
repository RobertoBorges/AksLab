#!/bin/bash

# Demo script for AKS Lab Terraform Infrastructure
# This script demonstrates the complete workflow without actually deploying resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[DEMO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "=============================================="
echo "🚀 AKS Lab Terraform Infrastructure Demo"
echo "=============================================="
echo ""

cd "$SCRIPT_DIR"

print_header "1. Validating Terraform Configuration"
print_status "Running validation script..."
if ./validate.sh; then
    print_status "✅ Validation successful!"
else
    print_status "❌ Validation failed!"
    exit 1
fi

echo ""
print_header "2. Checking Prerequisites"

# Check Terraform
if command -v terraform &> /dev/null; then
    print_status "✅ Terraform installed: $(terraform --version | head -n1)"
else
    print_status "❌ Terraform not found"
fi

# Check Azure CLI
if command -v az &> /dev/null; then
    print_status "✅ Azure CLI installed: $(az --version | head -n1)"
else
    print_status "❌ Azure CLI not found"
fi

echo ""
print_header "3. Configuration Files"

if [[ -f "terraform.tfvars.example" ]]; then
    print_status "✅ Example variables file exists"
    print_warning "Copy terraform.tfvars.example to terraform.tfvars and customize"
else
    print_status "❌ Example variables file missing"
fi

if [[ -f "deploy.sh" ]]; then
    print_status "✅ Deployment script available"
    print_warning "Usage: ./deploy.sh -e dev -a plan"
else
    print_status "❌ Deployment script missing"
fi

echo ""
print_header "4. Available Environments"

if [[ -d "environments" ]]; then
    print_status "Available environment configurations:"
    for env_file in environments/*.tfvars; do
        if [[ -f "$env_file" ]]; then
            env_name=$(basename "$env_file" .tfvars)
            print_status "  - $env_name: $env_file"
        fi
    done
else
    print_status "❌ No environment configurations found"
fi

echo ""
print_header "5. Terraform Modules"

if [[ -d "modules" ]]; then
    print_status "Available modules:"
    for module_dir in modules/*/; do
        if [[ -d "$module_dir" ]]; then
            module_name=$(basename "$module_dir")
            print_status "  - $module_name: $module_dir"
        fi
    done
else
    print_status "❌ No modules found"
fi

echo ""
print_header "6. Documentation"

docs=("README.md" "EXAMPLES.md" "TROUBLESHOOTING.md" "LOCAL_DEVELOPMENT.md")
for doc in "${docs[@]}"; do
    if [[ -f "$doc" ]]; then
        print_status "✅ $doc available"
    else
        print_status "❌ $doc missing"
    fi
done

echo ""
print_header "7. Deployment Workflow Demo"

print_status "Step 1: Copy example variables"
print_warning "cp terraform.tfvars.example terraform.tfvars"

print_status "Step 2: Customize variables"
print_warning "nano terraform.tfvars"

print_status "Step 3: Plan deployment"
print_warning "./deploy.sh -e dev -a plan"

print_status "Step 4: Apply deployment"
print_warning "./deploy.sh -e dev -a apply"

print_status "Step 5: Connect to AKS"
print_warning "az aks get-credentials --resource-group \$(terraform output -raw resource_group_name) --name \$(terraform output -raw aks_cluster_name)"

print_status "Step 6: Test connection"
print_warning "kubectl get nodes"

print_status "Step 7: Cleanup"
print_warning "./deploy.sh -e dev -a destroy"

echo ""
print_header "8. Resources That Will Be Created"

print_status "The infrastructure includes:"
print_status "  - Azure Kubernetes Service (AKS) cluster"
print_status "  - Azure Container Registry (ACR)"
print_status "  - Azure Key Vault"
print_status "  - Azure Cosmos DB (MongoDB API)"
print_status "  - Azure App Configuration"
print_status "  - Azure Log Analytics Workspace"
print_status "  - Azure Monitor and Prometheus"
print_status "  - Workload Identity configuration"
print_status "  - Advanced networking with Cilium"

echo ""
print_header "9. Next Steps"

print_status "To deploy the infrastructure:"
print_status "1. Ensure you have Azure CLI authenticated: az login"
print_status "2. Set your subscription: az account set --subscription your-subscription-id"
print_status "3. Copy and customize variables: cp terraform.tfvars.example terraform.tfvars"
print_status "4. Run validation: ./validate.sh"
print_status "5. Plan deployment: ./deploy.sh -e dev -a plan"
print_status "6. Apply deployment: ./deploy.sh -e dev -a apply"

echo ""
print_status "📚 Documentation:"
print_status "  - README.md - Main documentation"
print_status "  - EXAMPLES.md - Usage examples"
print_status "  - TROUBLESHOOTING.md - Common issues"
print_status "  - LOCAL_DEVELOPMENT.md - Developer guide"

echo ""
print_status "🎉 Demo completed successfully!"
print_status "The infrastructure is ready for deployment!"

echo ""
echo "=============================================="