@description('The base name for all resources')
param baseName string = 'octocat-supply'

@description('The environment name (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('The location for all resources')
param location string = resourceGroup().location

@description('Specifies whether to deploy Key Vault with RBAC authorization')
param useRbacAuthorization bool = true

@description('Object ID of the service principal that will access resources')
param objectId string = ''

@description('API secret value for Key Vault. Leave empty for no secret.')
@secure()
param apiSecretValue string = ''

@description('The SKU name for the App Service Plan')
param appServicePlanSku object = {
  name: 'B1'
  tier: 'Basic'
  size: 'B1'
  family: 'B'
  capacity: 1
}

@description('The SKU name for the Static Web App')
@allowed([
  'Free'
  'Standard'
])
param staticWebAppSku string = 'Standard'

// Generate resource names
var resourceToken = toLower('${baseName}-${environmentName}')
var apiServiceName = '${resourceToken}-api'
var appServicePlanName = '${resourceToken}-plan'
var frontendAppName = '${resourceToken}-frontend'
var keyVaultName = take('${resourceToken}-kv', 24) // Max 24 characters
var managedIdentityName = '${resourceToken}-id'

// Create a managed identity for secure communication between services
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: {
    'azd-env-name': environmentName
    application: 'OctoCAT Supply Chain'
  }
}

// Deploy Key Vault for secure secrets management
module keyVaultModule 'key-vault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    keyVaultName: keyVaultName
    location: location
    tenantId: subscription().tenantId
    objectId: !empty(objectId) ? objectId : managedIdentity.properties.principalId
    enableRbacAuthorization: useRbacAuthorization
    apiSecretValue: apiSecretValue
  }
}

// Assign Key Vault Secrets User role to the managed identity
resource keyVaultSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultModule.outputs.keyVaultResourceId, managedIdentity.id, 'sekretsUser')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deploy App Service for API backend
module apiAppService 'app-service.bicep' = {
  name: 'apiAppServiceDeployment'
  params: {
    appServiceName: apiServiceName
    appServicePlanName: appServicePlanName
    location: location
    sku: appServicePlanSku
    keyVaultId: keyVaultModule.outputs.keyVaultResourceId
    keyVaultUri: keyVaultModule.outputs.keyVaultUri
    managedIdentityId: managedIdentity.id
    managedIdentityPrincipalId: managedIdentity.properties.principalId
  }
}

// Deploy Static Web App for frontend
module staticWebApp 'static-web-app.bicep' = {
  name: 'staticWebAppDeployment'
  params: {
    staticWebAppName: frontendAppName
    location: location
    apiBackendUrl: 'https://${apiAppService.outputs.appServiceHostName}'
    managedIdentityId: managedIdentity.id
    sku: staticWebAppSku
  }
}

// Outputs for deployment scripts and CI/CD
output apiServiceUrl string = 'https://${apiAppService.outputs.appServiceHostName}'
output frontendUrl string = 'https://${staticWebApp.outputs.staticWebAppHostname}'
output keyVaultName string = keyVaultModule.outputs.keyVaultName
output keyVaultUri string = keyVaultModule.outputs.keyVaultUri
output managedIdentityId string = managedIdentity.id
output resourceGroupName string = resourceGroup().name