# Main deployment configuration for AKS and supporting services
# This template deploys an AKS cluster with supporting Azure resources

# Random string generation for unique resource names
resource "random_string" "seed" {
  length  = 4
  special = false
  upper   = false
  numeric = true
}

locals {
  short_seed = var.random_seed != null ? substr(var.random_seed, 0, 4) : random_string.seed.result
  resource_group_name = var.resource_group_name != null ? var.resource_group_name : "rg-akslab-${local.short_seed}"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  count    = var.resource_group_name == null ? 1 : 0
  name     = local.resource_group_name
  location = var.location

  tags = var.tags
}

data "azurerm_resource_group" "existing" {
  count = var.resource_group_name != null ? 1 : 0
  name  = var.resource_group_name
}

locals {
  rg_name = var.resource_group_name != null ? data.azurerm_resource_group.existing[0].name : azurerm_resource_group.main[0].name
}

# Module imports
module "monitoring" {
  source = "./modules/monitoring"

  location            = var.location
  random_seed         = local.short_seed
  resource_group_name = local.rg_name
  tags                = var.tags

  depends_on = [azurerm_resource_group.main]
}

module "aks" {
  source = "./modules/aks"

  location                   = var.location
  random_seed                = local.short_seed
  resource_group_name        = local.rg_name
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  monitoring_account_id      = module.monitoring.prometheus_id
  tags                       = var.tags

  depends_on = [module.monitoring]
}

module "cosmos_db" {
  source = "./modules/cosmos_db"

  location              = var.location
  random_seed           = local.short_seed
  resource_group_name   = local.rg_name
  aks_oidc_issuer_url   = module.aks.oidc_issuer_url
  tags                  = var.tags

  depends_on = [module.aks]
}

module "key_vault" {
  source = "./modules/key_vault"

  location              = var.location
  random_seed           = local.short_seed
  resource_group_name   = local.rg_name
  user_object_id        = var.user_object_id
  aks_oidc_issuer_url   = module.aks.oidc_issuer_url
  tags                  = var.tags

  depends_on = [module.aks]
}

module "app_configuration" {
  source = "./modules/app_configuration"

  location              = var.location
  random_seed           = local.short_seed
  resource_group_name   = local.rg_name
  aks_cluster_name      = module.aks.aks_cluster_name
  aks_oidc_issuer_url   = module.aks.oidc_issuer_url
  tags                  = var.tags

  depends_on = [module.aks]
}

module "container_registry" {
  source = "./modules/container_registry"

  location                       = var.location
  random_seed                    = local.short_seed
  resource_group_name            = local.rg_name
  aks_kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  tags                           = var.tags

  depends_on = [module.aks]
}