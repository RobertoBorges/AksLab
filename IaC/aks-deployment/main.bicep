// Main deployment template for AKS and supporting services
// This template deploys an AKS cluster with supporting Azure resources

// Parameters
@description('Random string for unique resource names')
param randomSeed string = uniqueString(subscription().subscriptionId, resourceGroup().id, utcNow())

@description('The object ID of the user to assign admin permissions')
@secure()
param userObjectId string

@description('Azure region to deploy resources')
param location string = resourceGroup().location

// Variables
var shortSeed = take(randomSeed, 4)

// Module imports
module logsModule 'modules/monitoring.bicep' = {
  name: 'logsDeployment'
  params: {
    location: location
    randomSeed: shortSeed
  }
}

module aksClusterModule 'modules/aks.bicep' = {
  name: 'aksDeployment'
  params: {
    location: location
    randomSeed: shortSeed
    logAnalyticsWorkspaceId: logsModule.outputs.logAnalyticsWorkspaceId
    monitoringAccountId: logsModule.outputs.prometheusId
  }
  dependsOn: [
    logsModule
  ]
}

module cosmosDBModule 'modules/cosmosdb.bicep' = {
  name: 'cosmosDeployment'
  params: {
    location: location
    randomSeed: shortSeed
    aksOidcIssuerUrl: aksClusterModule.outputs.oidcIssuerUrl
  }
}

module keyVaultModule 'modules/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    randomSeed: shortSeed
    userObjectId: userObjectId
    aksOidcIssuerUrl: aksClusterModule.outputs.oidcIssuerUrl
  }
}

module appConfigModule 'modules/appconfig.bicep' = {
  name: 'appConfigDeployment'
  params: {
    location: location
    randomSeed: shortSeed
    aksClusterName: aksClusterModule.outputs.aksClusterName
    aksOidcIssuerUrl: aksClusterModule.outputs.oidcIssuerUrl
  }
  dependsOn: [
    aksClusterModule
  ]
}

module containerRegistryModule 'modules/containerregistry.bicep' = {
  name: 'containerRegistryDeployment'
  params: {
    location: location
    randomSeed: shortSeed
    aksKubeletIdentityObjectId: aksClusterModule.outputs.kubeletIdentityObjectId
  }
  dependsOn: [
    aksClusterModule
  ]
}

// Outputs
output aksClusterName string = aksClusterModule.outputs.aksClusterName
output aksNodeResourceGroupName string = aksClusterModule.outputs.nodeResourceGroupName
output containerRegistryName string = containerRegistryModule.outputs.acrName
output keyVaultName string = keyVaultModule.outputs.akvName
output appConfigName string = appConfigModule.outputs.acName
output cosmosDbAccountName string = cosmosDBModule.outputs.cosmosDbAccountName
output mongoIdentityClientId string = cosmosDBModule.outputs.mongoIdentityClientId
output mongoListConnectionStringUrl string = cosmosDBModule.outputs.mongoListConnectionStringUrl
