output "akv_name" {
  description = "The name of the Azure Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_identity_id" {
  description = "The ID of the Key Vault user-assigned managed identity"
  value       = azurerm_user_assigned_identity.key_vault.id
}

output "key_vault_identity_client_id" {
  description = "The client ID of the Key Vault user-assigned managed identity"
  value       = azurerm_user_assigned_identity.key_vault.client_id
}