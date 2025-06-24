output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "node_resource_group_name" {
  description = "The auto-generated resource group containing the AKS cluster resources"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "kubelet_identity_object_id" {
  description = "The object ID of the kubelet identity"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}