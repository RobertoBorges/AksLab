output "cosmos_db_account_name" {
  description = "The name of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.mongo.name
}

output "mongo_identity_client_id" {
  description = "The client ID of the MongoDB user-assigned managed identity"
  value       = azurerm_user_assigned_identity.mongo.client_id
}

output "mongo_list_connection_string_url" {
  description = "The endpoint for listing MongoDB connection strings"
  value       = "https://management.azure.com${azurerm_cosmosdb_account.mongo.id}/listConnectionStrings?api-version=2021-04-15"
}