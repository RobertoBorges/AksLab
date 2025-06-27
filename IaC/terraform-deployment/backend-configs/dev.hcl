# Development Environment Backend Configuration
# This file contains the backend configuration for the development environment
# The actual values should be provided via GitHub secrets during CI/CD

# Example configuration - values will be overridden by GitHub Actions
resource_group_name   = "rg-terraform-state-dev"
storage_account_name  = "tfstatedevXXXX"
container_name        = "tfstate"
key                   = "dev.terraform.tfstate"