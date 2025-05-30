// Key Vault Module
// Deploys an Azure Key Vault and configures workload identity access

@description('Azure region to deploy resources')
param location string

@description('Random seed for unique resource names')
param randomSeed string

@description('Object ID of the user to grant Key Vault Administrator permissions')
param userObjectId string

@description('AKS OIDC issuer URL for workload identity')
param aksOidcIssuerUrl string

// Resource names
var keyVaultName = 'mykeyvault${randomSeed}'
var keyVaultIdentityName = 'mykeyvault${randomSeed}-identity'

// Role definitions
var keyVaultAdministratorRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2024-12-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    enableSoftDelete: false
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
  }
}

// User-assigned managed identity for Key Vault access
resource keyVaultIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: keyVaultIdentityName
  location: location
}

// Federated identity credentials for Kubernetes workload identity
resource keyVaultFederatedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30' = {
  name: '${keyVaultIdentityName}/${keyVaultIdentityName}'
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: aksOidcIssuerUrl
    subject: 'system:serviceaccount:default:contoso-air'
  }
  dependsOn: [
    keyVaultIdentity
  ]
}

// RBAC role assignment for Key Vault access (managed identity)
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, keyVaultIdentity.id)
  properties: {
    principalId: keyVaultIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: keyVaultAdministratorRole
  }
  dependsOn: [
    keyVault
    keyVaultIdentity
  ]
}

// RBAC role assignment for Key Vault access (for user)
resource userRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(subscription().subscriptionId, resourceGroup().id, userObjectId, 'Key Vault Admin')
  properties: {
    principalId: userObjectId
    principalType: 'User'
    roleDefinitionId: keyVaultAdministratorRole
  }
  dependsOn: [
    keyVault
  ]
}

// Outputs
output akvName string = keyVaultName
output keyVaultIdentityId string = keyVaultIdentity.id
output keyVaultIdentityClientId string = keyVaultIdentity.properties.clientId
