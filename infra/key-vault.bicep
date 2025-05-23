@description('The name of the Key Vault')
param keyVaultName string

@description('The location for the Key Vault')
param location string

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault')
param tenantId string = subscription().tenantId

@description('Object ID of the service principal or managed identity that will access the Key Vault')
param objectId string

@description('The SKU of the Key Vault')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the Key Vault')
param enabledForDeployment bool = true

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the Key Vault for VM disk encryption')
param enabledForDiskEncryption bool = true

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the Key Vault')
param enabledForTemplateDeployment bool = true

@description('Specifies whether protection against purge is enabled for this vault')
param enablePurgeProtection bool = true

@description('Specifies whether the Key Vault uses Role Based Access Control (RBAC) for authorization')
param enableRbacAuthorization bool = true

@description('Specifies the soft-delete retention period in days')
param softDeleteRetentionInDays int = 7

@description('API secret value for the API Key Vault secret')
@secure()
param apiSecretValue string = ''

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    tenantId: tenantId
    enablePurgeProtection: enablePurgeProtection ? true : null
    enableRbacAuthorization: enableRbacAuthorization
    softDeleteRetentionInDays: softDeleteRetentionInDays
    accessPolicies: enableRbacAuthorization ? [] : [
      {
        tenantId: tenantId
        objectId: objectId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
          ]
          keys: [
            'get'
            'list'
            'create'
          ]
        }
      }
    ]
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
  tags: {
    application: 'OctoCAT Supply Chain'
    component: 'Security'
  }
}

// Create a secret for the API key if a value is provided
resource apiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(apiSecretValue)) {
  name: '${keyVault.name}/ApiKey'
  properties: {
    value: apiSecretValue
    contentType: 'text/plain'
  }
}

@description('The URI of the Key Vault')
output keyVaultUri string = keyVault.properties.vaultUri

@description('The Resource ID of the Key Vault')
output keyVaultResourceId string = keyVault.id

@description('The name of the Key Vault')
output keyVaultName string = keyVault.name
