# Container Registry Module
# Deploys Azure Container Registry and configures AKS to pull images

locals {
  acr_name = "mycontainerregistry${var.random_seed}"
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Standard"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# RBAC role assignment for AKS to pull images
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_kubelet_identity_object_id
  principal_type       = "ServicePrincipal"
}