# Development environment variables

random_seed = "dev001"
location    = "East US"

# Replace this with your actual Azure AD Object ID
# Get it with: az ad signed-in-user show --query id -o tsv
user_object_id = "your-user-object-id-here"

tags = {
  Environment = "Development"
  Project     = "AKS Lab"
  ManagedBy   = "Terraform"
  Owner       = "DevTeam"
}