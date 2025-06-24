output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "The login server URL of the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}