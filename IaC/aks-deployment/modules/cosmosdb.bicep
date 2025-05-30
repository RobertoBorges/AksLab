// Cosmos DB Module
// Deploys an Azure Cosmos DB MongoDB API account and database

@description('Azure region to deploy resources')
param location string

@description('Random seed for unique resource names')
param randomSeed string

@description('AKS OIDC issuer URL for workload identity')
param aksOidcIssuerUrl string

// Resource names
var mongoDbAccountName = 'mymongo${randomSeed}'
var mongoIdentityName = 'mymongo${randomSeed}-identity'

// Role definitions
var documentDBAccountContributorRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5bd9cd88-fe45-4216-938b-f97437e15450')

// MongoDB Account
resource mongoDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' = {
  name: mongoDbAccountName
  kind: 'MongoDB'
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    apiProperties: {
      serverVersion: '7.0'
    }
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

// Test database
resource testDatabase 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2024-12-01-preview' = {
  name: '${mongoDbAccountName}/test'
  properties: {
    resource: {
      id: 'test'
    }
  }
  dependsOn: [
    mongoDbAccount
  ]
}

// User-assigned managed identity for MongoDB access
resource mongoIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: mongoIdentityName
  location: location
}

// Federation identity credentials for Kubernetes workload identity
resource mongoFederatedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30' = {
  name: '${mongoIdentityName}/${mongoIdentityName}'
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: aksOidcIssuerUrl
    subject: 'system:serviceaccount:default:contoso-air'
  }
  dependsOn: [
    mongoIdentity
  ]
}

// RBAC role assignment for MongoDB access
resource mongoRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: mongoDbAccount
  name: guid(mongoDbAccount.id, mongoIdentity.id)
  properties: {
    principalId: mongoIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: documentDBAccountContributorRole
  }
  dependsOn: [
    mongoDbAccount
    mongoIdentity
  ]
}

// Outputs
output cosmosDbAccountName string = mongoDbAccountName
output mongoIdentityClientId string = mongoIdentity.properties.clientId
output mongoListConnectionStringUrl string = 'https://management.azure.com${mongoDbAccount.id}/listConnectionStrings?api-version=2021-04-15'
