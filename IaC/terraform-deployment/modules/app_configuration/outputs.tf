output "ac_name" {
  description = "The name of the Azure App Configuration"
  value       = azurerm_app_configuration.main.name
}

output "app_config_identity_id" {
  description = "The ID of the App Configuration user-assigned managed identity"
  value       = azurerm_user_assigned_identity.app_config.id
}

output "app_config_identity_client_id" {
  description = "The client ID of the App Configuration user-assigned managed identity"
  value       = azurerm_user_assigned_identity.app_config.client_id
}