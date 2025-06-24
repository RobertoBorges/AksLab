# App Configuration Module
# Deploys Azure App Configuration service and configures workload identity access

locals {
  app_config_name          = "myappconfig${var.random_seed}"
  app_config_identity_name = "myappconfig${var.random_seed}-identity"
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# App Configuration
resource "azurerm_app_configuration" "main" {
  name                = local.app_config_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku                 = "standard"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# User-assigned managed identity for App Configuration access
resource "azurerm_user_assigned_identity" "app_config" {
  name                = local.app_config_identity_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = var.tags
}

# Federation identity credentials for Kubernetes workload identity
resource "azurerm_federated_identity_credential" "app_config" {
  name                = local.app_config_identity_name
  resource_group_name = data.azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.app_config.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:default:contoso-air"
}

# RBAC role assignment for App Configuration access
resource "azurerm_role_assignment" "app_config" {
  scope                = azurerm_app_configuration.main.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = azurerm_user_assigned_identity.app_config.principal_id
  principal_type       = "ServicePrincipal"
}