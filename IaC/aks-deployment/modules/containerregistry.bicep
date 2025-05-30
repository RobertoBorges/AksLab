// Container Registry Module
// Deploys Azure Container Registry and configures AKS to pull images

@description('Azure region to deploy resources')
param location string

@description('Random seed for unique resource names')
param randomSeed string

@description('Object ID of the AKS kubelet identity to grant pull access')
param aksKubeletIdentityObjectId string

// Resource names
var acrName = 'mycontainerregistry${randomSeed}'

// ACR Pull role definition ID
var acrPullRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Azure Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// RBAC role assignment for AKS to pull images
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(subscription().subscriptionId, resourceGroup().id, acrName, 'AcrPullRole')
  properties: {
    principalId: aksKubeletIdentityObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleDefinitionId
  }
  dependsOn: [
    containerRegistry
  ]
}

// Outputs
output acrName string = acrName
output acrLoginServer string = containerRegistry.properties.loginServer
