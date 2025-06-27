# Monitoring Module
# Deploys Azure Monitor, Log Analytics Workspace, and Grafana for AKS monitoring

locals {
  log_analytics_name = "mylogs${var.random_seed}"
  prometheus_name    = "myprometheus${var.random_seed}"
  grafana_name       = "mygrafana${var.random_seed}"
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = local.log_analytics_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Azure Monitor for Prometheus
resource "azurerm_monitor_workspace" "prometheus" {
  name                = local.prometheus_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  tags = var.tags
}

# Grafana Dashboard
resource "azurerm_dashboard_grafana" "main" {
  name                  = local.grafana_name
  resource_group_name   = data.azurerm_resource_group.main.name
  location              = var.location
  grafana_major_version = "10"

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus.id
  }

  tags = var.tags
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}