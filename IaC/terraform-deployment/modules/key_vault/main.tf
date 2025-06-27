# Key Vault Module
# Deploys an Azure Key Vault and configures workload identity access

locals {
  key_vault_name          = "mykeyvault${var.random_seed}"
  key_vault_identity_name = "mykeyvault${var.random_seed}-identity"
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization  = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = var.tags
}

# User-assigned managed identity for Key Vault access
resource "azurerm_user_assigned_identity" "key_vault" {
  name                = local.key_vault_identity_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = var.tags
}

# Federated identity credentials for Kubernetes workload identity
resource "azurerm_federated_identity_credential" "key_vault" {
  name                = local.key_vault_identity_name
  resource_group_name = data.azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.key_vault.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:default:contoso-air"
}

# RBAC role assignment for Key Vault access (managed identity)
resource "azurerm_role_assignment" "key_vault_identity" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azurerm_user_assigned_identity.key_vault.principal_id
  principal_type       = "ServicePrincipal"
}

# RBAC role assignment for Key Vault access (for user)
resource "azurerm_role_assignment" "key_vault_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.user_object_id
  principal_type       = "User"
}