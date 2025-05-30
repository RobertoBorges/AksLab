// App Configuration Module
// Deploys Azure App Configuration service and configures workload identity access

@description('Azure region to deploy resources')
param location string

@description('Random seed for unique resource names')
param randomSeed string

@description('AKS OIDC issuer URL for workload identity')
param aksOidcIssuerUrl string

@description('AKS cluster name for extension deployment')
param aksClusterName string

// Resource names
var appConfigName = 'myappconfig${randomSeed}'
var appConfigIdentityName = 'myappconfig${randomSeed}-identity'

// Role definitions
var appConfigStoreDataOwnerRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b')

// App Configuration
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2024-05-01' = {
  name: appConfigName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enablePurgeProtection: false
  }
  sku: {
    name: 'standard'
  }
}

// User-assigned managed identity for App Configuration access
resource appConfigIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: appConfigIdentityName
  location: location
}

// Federation identity credentials for Kubernetes workload identity
resource appConfigFederatedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30' = {
  name: '${appConfigIdentityName}/${appConfigIdentityName}'
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: aksOidcIssuerUrl
    subject: 'system:serviceaccount:default:contoso-air'
  }
  dependsOn: [
    appConfigIdentity
  ]
}

// RBAC role assignment for App Configuration access
resource appConfigRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: appConfig
  name: guid(appConfig.id, appConfigIdentity.id)
  properties: {
    principalId: appConfigIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: appConfigStoreDataOwnerRole
  }
  dependsOn: [
    appConfig
    appConfigIdentity
  ]
}

// App Configuration Kubernetes Provider Extension
// Note: This is defined in the aks.bicep module to properly scope to the AKS resource

// Outputs
output acName string = appConfigName
output appConfigIdentityId string = appConfigIdentity.id
output appConfigIdentityClientId string = appConfigIdentity.properties.clientId
