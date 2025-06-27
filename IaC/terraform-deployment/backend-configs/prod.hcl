# Production Environment Backend Configuration
# This file contains the backend configuration for the production environment
# The actual values should be provided via GitHub secrets during CI/CD

# Example configuration - values will be overridden by GitHub Actions
resource_group_name   = "rg-terraform-state-prod"
storage_account_name  = "tfstateprodXXXX"
container_name        = "tfstate"
key                   = "prod.terraform.tfstate"