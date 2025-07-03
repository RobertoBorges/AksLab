# Cosmos DB Module
# Deploys an Azure Cosmos DB MongoDB API account and database

locals {
  mongo_db_account_name = "mymongo${var.random_seed}"
  mongo_identity_name   = "mymongo${var.random_seed}-identity"
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# MongoDB Account
resource "azurerm_cosmosdb_account" "mongo" {
  name                = local.mongo_db_account_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "MongoDB"
  mongo_server_version = "4.2"

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }

  tags = var.tags
}

# Test database
resource "azurerm_cosmosdb_mongo_database" "test" {
  name                = "test"
  resource_group_name = data.azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.mongo.name
}

# User-assigned managed identity for MongoDB access
resource "azurerm_user_assigned_identity" "mongo" {
  name                = local.mongo_identity_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = var.tags
}

# Federation identity credentials for Kubernetes workload identity
resource "azurerm_federated_identity_credential" "mongo" {
  name                = local.mongo_identity_name
  resource_group_name = data.azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.mongo.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:default:contoso-air"
}

# RBAC role assignment for MongoDB access
resource "azurerm_role_assignment" "mongo" {
  scope                = azurerm_cosmosdb_account.mongo.id
  role_definition_name = "DocumentDB Account Contributor"
  principal_id         = azurerm_user_assigned_identity.mongo.principal_id
  principal_type       = "ServicePrincipal"
}