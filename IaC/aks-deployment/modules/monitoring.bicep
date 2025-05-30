// Monitoring Module
// Deploys Azure Monitor, Log Analytics Workspace, and Grafana for AKS monitoring

@description('Azure region to deploy resources')
param location string

@description('Random seed for unique resource names')
param randomSeed string

// Resource names
var logAnalyticsName = 'mylogs${randomSeed}'
var prometheusName = 'myprometheus${randomSeed}'
var grafanaName = 'mygrafana${randomSeed}'

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: logAnalyticsName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

// Azure Monitor for Prometheus
resource prometheus 'Microsoft.Monitor/accounts@2023-04-03' = {
  name: prometheusName
  location: location
}

// Grafana Dashboard
resource grafana 'Microsoft.Dashboard/grafana@2024-10-01' = {
  name: grafanaName
  location: location
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: [
        {
          azureMonitorWorkspaceResourceId: prometheus.id
        }
      ]
    }
  }
  dependsOn: [
    prometheus
  ]
}

// Outputs
output logAnalyticsWorkspaceId string = logAnalytics.id
output prometheusId string = prometheus.id
output grafanaId string = grafana.id
