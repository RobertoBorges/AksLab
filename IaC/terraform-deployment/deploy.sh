#!/bin/bash

# Quick deployment script for AKS Lab Terraform infrastructure
# This script helps deploy the infrastructure with minimal configuration

set -e

# Default values
ENVIRONMENT="dev"
ACTION="plan"
INTERACTIVE=true
BACKEND_CONFIG=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment    Environment to deploy (dev/prod) [default: dev]"
    echo "  -a, --action         Action to perform (plan/apply/destroy) [default: plan]"
    echo "  -y, --yes            Non-interactive mode (auto-approve)"
    echo "  -b, --backend-config Backend configuration file path"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e dev -a plan                    # Plan development environment"
    echo "  $0 -e prod -a apply -y              # Apply production environment non-interactively"
    echo "  $0 -e dev -a destroy                # Destroy development environment"
    echo "  $0 -b backend-configs/dev.hcl       # Use specific backend configuration"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -y|--yes)
            INTERACTIVE=false
            shift
            ;;
        -b|--backend-config)
            BACKEND_CONFIG="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be 'dev' or 'prod'"
    exit 1
fi

# Validate action
if [[ "$ACTION" != "plan" && "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
    print_error "Invalid action: $ACTION. Must be 'plan', 'apply', or 'destroy'"
    exit 1
fi

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

print_header "🚀 AKS Lab Terraform Deployment"
print_status "Environment: $ENVIRONMENT"
print_status "Action: $ACTION"
print_status "Interactive: $INTERACTIVE"
print_status "Working directory: $SCRIPT_DIR"
echo ""

# Change to script directory
cd "$SCRIPT_DIR"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

print_status "Terraform version: $(terraform --version | head -n1)"

# Check if variables file exists
VAR_FILE="environments/${ENVIRONMENT}.tfvars"
if [[ ! -f "$VAR_FILE" ]]; then
    print_error "Variables file not found: $VAR_FILE"
    print_status "Available environments:"
    ls -1 environments/*.tfvars 2>/dev/null | sed 's/environments\//  - /' | sed 's/\.tfvars//' || echo "  No environment files found"
    exit 1
fi

# Set backend configuration
if [[ -n "$BACKEND_CONFIG" ]]; then
    if [[ ! -f "$BACKEND_CONFIG" ]]; then
        print_error "Backend configuration file not found: $BACKEND_CONFIG"
        exit 1
    fi
    BACKEND_ARGS="-backend-config=$BACKEND_CONFIG"
else
    if [[ -f "backend-configs/${ENVIRONMENT}.hcl" ]]; then
        BACKEND_ARGS="-backend-config=backend-configs/${ENVIRONMENT}.hcl"
        print_status "Using backend configuration: backend-configs/${ENVIRONMENT}.hcl"
    else
        print_warning "No backend configuration found. Using local state."
        BACKEND_ARGS="-backend=false"
    fi
fi

# Initialize Terraform
print_status "Initializing Terraform..."
if [[ "$BACKEND_ARGS" == "-backend=false" ]]; then
    terraform init -backend=false
else
    terraform init $BACKEND_ARGS
fi

# Validate configuration
print_status "Validating Terraform configuration..."
terraform validate

# Perform the requested action
case $ACTION in
    "plan")
        print_status "Creating Terraform plan..."
        terraform plan -var-file="$VAR_FILE" -out="${ENVIRONMENT}.tfplan"
        print_status "✅ Plan created successfully: ${ENVIRONMENT}.tfplan"
        ;;
    "apply")
        # Check if plan file exists
        if [[ -f "${ENVIRONMENT}.tfplan" ]]; then
            print_status "Applying existing plan: ${ENVIRONMENT}.tfplan"
            if [[ "$INTERACTIVE" == true ]]; then
                terraform apply "${ENVIRONMENT}.tfplan"
            else
                terraform apply -auto-approve "${ENVIRONMENT}.tfplan"
            fi
        else
            print_status "Creating and applying new plan..."
            if [[ "$INTERACTIVE" == true ]]; then
                terraform apply -var-file="$VAR_FILE"
            else
                terraform apply -auto-approve -var-file="$VAR_FILE"
            fi
        fi
        print_status "✅ Infrastructure deployed successfully!"
        ;;
    "destroy")
        print_warning "⚠️  This will destroy all resources in the $ENVIRONMENT environment!"
        if [[ "$INTERACTIVE" == true ]]; then
            read -p "Are you sure you want to continue? (yes/no): " -r
            if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                print_status "Aborted."
                exit 0
            fi
        fi
        print_status "Destroying infrastructure..."
        if [[ "$INTERACTIVE" == true ]]; then
            terraform destroy -var-file="$VAR_FILE"
        else
            terraform destroy -auto-approve -var-file="$VAR_FILE"
        fi
        print_status "✅ Infrastructure destroyed successfully!"
        ;;
esac

# Show outputs if apply was successful
if [[ "$ACTION" == "apply" ]]; then
    print_status "Getting deployment outputs..."
    terraform output
fi

echo ""
print_status "🎉 Operation completed successfully!"