output "resource_group_name" {
  description = "The name of the resource group"
  value       = local.rg_name
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.aks_cluster_name
}

output "aks_node_resource_group_name" {
  description = "The auto-generated resource group containing the AKS cluster resources"
  value       = module.aks.node_resource_group_name
}

output "container_registry_name" {
  description = "The name of the Azure Container Registry"
  value       = module.container_registry.acr_name
}

output "key_vault_name" {
  description = "The name of the Azure Key Vault"
  value       = module.key_vault.akv_name
}

output "app_config_name" {
  description = "The name of the Azure App Configuration"
  value       = module.app_configuration.ac_name
}

output "cosmos_db_account_name" {
  description = "The name of the Cosmos DB account"
  value       = module.cosmos_db.cosmos_db_account_name
}

output "mongo_identity_client_id" {
  description = "The client ID of the MongoDB user-assigned managed identity"
  value       = module.cosmos_db.mongo_identity_client_id
}

output "mongo_list_connection_string_url" {
  description = "The endpoint for listing MongoDB connection strings"
  value       = module.cosmos_db.mongo_list_connection_string_url
}

output "grafana_url" {
  description = "The URL of the Grafana dashboard"
  value       = "https://portal.azure.com/#resource${module.monitoring.grafana_id}"
}