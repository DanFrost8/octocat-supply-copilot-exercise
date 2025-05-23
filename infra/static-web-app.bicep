@description('The name of the Static Web App')
param staticWebAppName string

@description('The location for the Static Web App')
param location string

@description('The URL of the API backend')
param apiBackendUrl string

@description('The ID of the Managed Identity')
param managedIdentityId string

@description('Static Web App SKU')
@allowed([
  'Free'
  'Standard'
])
param sku string = 'Standard'

resource staticWebApp 'Microsoft.Web/staticSites@2024-04-01' = {
  name: staticWebAppName
  location: location
  sku: {
    name: sku
    tier: sku
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    provider: 'Custom'
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    enterpriseGradeCdnStatus: 'Disabled'
    keyVaultReferenceIdentity: managedIdentityId
  }
  tags: {
    'azd-service-name': 'frontend'
    application: 'OctoCAT Supply Chain'
    component: 'Frontend'
  }
}

// Configure app settings for the Static Web App
resource staticWebAppSettings 'Microsoft.Web/staticSites/config@2024-04-01' = {
  parent: staticWebApp
  name: 'appsettings'
  properties: {
    VITE_API_URL: apiBackendUrl
  }
}

@description('The Static Web App default hostname')
output staticWebAppHostname string = staticWebApp.properties.defaultHostname

@description('The Static Web App resource ID')
output staticWebAppResourceId string = staticWebApp.id

@description('The Static Web App name')
output staticWebAppName string = staticWebApp.name
