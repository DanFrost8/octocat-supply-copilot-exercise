# OctoCAT Supply Chain Infrastructure

This directory contains the Azure infrastructure as code (IaC) using Bicep for deploying the OctoCAT Supply Chain application securely to Azure.

## Architecture

The infrastructure consists of:

- **Azure App Service**: Hosts the Express.js API backend
- **Azure Static Web App**: Hosts the React frontend
- **Azure Key Vault**: Securely stores secrets
- **User-Assigned Managed Identity**: Provides secure communication between services

## Security Features

- HTTPS-only communication
- TLS 1.2+ enforcement
- Managed Identity for secure access to Key Vault
- CORS configuration to restrict cross-origin requests
- Role-based access control for Key Vault
- Diagnostics and logging for monitoring and auditing

## Prerequisites

- Azure CLI installed
- Azure Developer CLI (azd) installed
- Azure Subscription
- Access permissions to create resources

## Deployment

### Option 1: Using Azure Developer CLI (Recommended)

1. Login to Azure:
   ```bash
   az login
   ```

2. Set the default subscription:
   ```bash
   az account set --subscription <subscription-id>
   ```

3. Initialize and deploy with azd:
   ```bash
   azd up
   ```

### Option 2: Using Azure CLI

1. Login to Azure:
   ```bash
   az login
   ```

2. Set the default subscription:
   ```bash
   az account set --subscription <subscription-id>
   ```

3. Create a resource group:
   ```bash
   az group create --name octocat-supply-rg --location eastus
   ```

4. Deploy the Bicep template:
   ```bash
   az deployment group create \
     --resource-group octocat-supply-rg \
     --template-file main.bicep \
     --parameters main.parameters.json
   ```

## Customization

Edit the `main.parameters.json` file to customize the deployment:

- **baseName**: Base name for all resources
- **environmentName**: Environment (dev, test, prod)
- **location**: Azure region for deployment
- **useRbacAuthorization**: Whether to use RBAC for Key Vault
- **objectId**: Object ID of the principal for Key Vault access
- **appServicePlanSku**: SKU for App Service Plan
- **staticWebAppSku**: SKU for Static Web App ('Free' or 'Standard')

## Post-Deployment

After deployment, you'll need to:

1. Configure your CI/CD pipeline to deploy the application code
2. Set up custom domains if needed
3. Configure additional security settings as required

## Outputs

The deployment provides the following outputs:

- **apiServiceUrl**: URL of the deployed API service
- **frontendUrl**: URL of the deployed frontend application
- **keyVaultName**: Name of the deployed Key Vault
- **keyVaultUri**: URI of the deployed Key Vault
- **managedIdentityId**: ID of the created Managed Identity
- **resourceGroupName**: Name of the deployed resource group
