# Production environment variables

random_seed = "prod01"
location    = "East US"

# Replace this with your actual Azure AD Object ID
# For production, consider using Key Vault references or environment variables
user_object_id = "your-user-object-id-here"

tags = {
  Environment = "Production"
  Project     = "AKS Lab"
  ManagedBy   = "Terraform"
  Owner       = "OpsTeam"
  CostCenter  = "Engineering"
}