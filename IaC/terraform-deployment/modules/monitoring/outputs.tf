output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "prometheus_id" {
  description = "The ID of the Azure Monitor Workspace for Prometheus"
  value       = azurerm_monitor_workspace.prometheus.id
}

output "grafana_id" {
  description = "The ID of the Grafana instance"
  value       = azurerm_dashboard_grafana.main.id
}