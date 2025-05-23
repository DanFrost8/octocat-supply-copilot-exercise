@description('The name of the App Service')
param appServiceName string

@description('The name of the App Service Plan')
param appServicePlanName string

@description('The location for the App Service')
param location string

@description('The SKU of the App Service Plan')
param sku object = {
  name: 'B1'
  tier: 'Basic'
  size: 'B1'
  family: 'B'
  capacity: 1
}

@description('The ID of the Key Vault Resource')
param keyVaultId string

@description('The URI of the Key Vault')
param keyVaultUri string

@description('The ID of the Managed Identity')
param managedIdentityId string

@description('The Principal ID of the Managed Identity')
param managedIdentityPrincipalId string

// Create an App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku.name
    tier: sku.tier
    size: sku.size
    family: sku.family
    capacity: sku.capacity
  }
  properties: {
    reserved: true // Required for Linux
  }
  tags: {
    application: 'OctoCAT Supply Chain'
    component: 'API'
  }
}

// Create an App Service for the API
resource appService 'Microsoft.Web/sites@2024-04-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    clientAffinityEnabled: false
    httpsOnly: true // Enforce HTTPS
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts' // Node.js 20 LTS
      alwaysOn: true
      minTlsVersion: '1.2' // Enforce TLS 1.2+
      ftpsState: 'Disabled' // Disable FTPS for security
      http20Enabled: true // Enable HTTP/2
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://index.docker.io/v1'
        }
        {
          name: 'KEY_VAULT_URI'
          value: keyVaultUri
        }
      ]
      cors: {
        allowedOrigins: [
          'https://localhost:5137'
          'https://${appServiceName}-frontend.azurestaticapps.net' // Will match our frontend domain
        ]
        supportCredentials: true
      }
      ipSecurityRestrictions: [] // No IP restrictions by default
    }
    keyVaultReferenceIdentity: managedIdentityId
  }
  tags: {
    'azd-service-name': 'api'
    application: 'OctoCAT Supply Chain'
    component: 'API'
  }
}

// Create a deployment slot for staging
resource stagingSlot 'Microsoft.Web/sites/slots@2024-04-01' = {
  parent: appService
  name: 'staging'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    clientAffinityEnabled: false
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      alwaysOn: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://index.docker.io/v1'
        }
        {
          name: 'KEY_VAULT_URI'
          value: keyVaultUri
        }
      ]
      cors: {
        allowedOrigins: [
          'https://localhost:5137'
          'https://${appServiceName}-frontend.azurestaticapps.net'
        ]
        supportCredentials: true
      }
    }
    keyVaultReferenceIdentity: managedIdentityId
  }
  tags: {
    'azd-service-name': 'api-staging'
    application: 'OctoCAT Supply Chain'
    component: 'API'
  }
}

// Create a diagnostic setting to log all events
resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: appService
  properties: {
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspace.id
  }
}

// Create Log Analytics workspace for diagnostics
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${appServiceName}-logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
  tags: {
    application: 'OctoCAT Supply Chain'
    component: 'Monitoring'
  }
}

@description('The hostname of the App Service')
output appServiceHostName string = appService.properties.defaultHostName

@description('The App Service resource ID')
output appServiceResourceId string = appService.id

@description('The App Service name')
output appServiceName string = appService.name
