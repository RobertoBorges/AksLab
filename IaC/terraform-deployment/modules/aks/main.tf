# AKS Cluster Module
# Deploys an Azure Kubernetes Service cluster with advanced configuration

locals {
  aks_cluster_name = "myakscluster${var.random_seed}"
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_cluster_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  dns_prefix          = "myakscluster"
  
  sku_tier = "Standard"

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "systempool"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
    type       = "VirtualMachineScaleSets"
    
    upgrade_settings {
      max_surge = "10%"
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    dns_service_ip      = "10.0.0.10"
    service_cidr        = "10.0.0.0/16"
    load_balancer_sku   = "standard"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  azure_policy_enabled = true

  monitor_metrics {
    annotations_allowed = "*"
    labels_allowed      = "*"
  }

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  workload_autoscaler_profile {
    keda_enabled                    = true
    vertical_pod_autoscaler_enabled = true
  }

  web_app_routing {
    dns_zone_ids = []
  }

  tags = var.tags
}

# App Configuration Kubernetes Provider Extension
resource "azurerm_kubernetes_cluster_extension" "app_config" {
  name           = "appconfigurationkubernetesprovider"
  cluster_id     = azurerm_kubernetes_cluster.aks.id
  extension_type = "microsoft.appconfiguration"

  configuration_settings = {
    "global.clusterType" = "managedclusters"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Monitoring Integration - Data Collection Endpoint
resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  name                = "MSProm-${var.location}-${local.aks_cluster_name}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  kind                = "Linux"
  description         = "Data Collection Endpoint for Prometheus"

  tags = var.tags
}

# Data Collection Rule Association
resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  name                    = "configurationAccessEndpoint"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus.id
}

# Container Insights Data Collection Rule
resource "azurerm_monitor_data_collection_rule" "container_insights" {
  name                = "MSCI-${var.location}-${local.aks_cluster_name}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  kind                = "Linux"

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace_id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = ["ciworkspace"]
  }

  data_sources {
    extension {
      streams            = ["Microsoft-ContainerInsights-Group-Default"]
      extension_name     = "ContainerInsights"
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval                 = "1m"
          namespaceFilteringMode   = "Off"
          enableContainerLogV2     = true
        }
      })
      name = "ContainerInsightsExtension"
    }
  }

  tags = var.tags
}