# OctoCAT Supply Chain Azure Deployment Guide

This guide explains how to deploy the OctoCAT Supply Chain application to Azure using the provided infrastructure as code (Bicep) templates.

## Architecture Overview

The deployed solution consists of:

1. **Azure App Service** - Hosts the Express.js API backend
2. **Azure Static Web App** - Hosts the React frontend
3. **Azure Key Vault** - Securely stores configuration secrets
4. **User-Assigned Managed Identity** - Enables secure authentication between services

![Architecture Diagram]
```
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│               │     │               │     │               │
│   Static      │────▶│   App         │────▶│   Key         │
│   Web App     │     │   Service     │     │   Vault       │
│   (Frontend)  │     │   (API)       │     │               │
│               │     │               │     │               │
└───────────────┘     └───────────────┘     └───────────────┘
        ▲                     ▲                    ▲
        │                     │                    │
        └─────────────────────┼────────────────────┘
                              │
                     ┌────────┴───────┐
                     │                │
                     │   Managed      │
                     │   Identity     │
                     │                │
                     └────────────────┘
```

## Security Features

- HTTPS-only communication between all services
- TLS 1.2+ enforcement for all endpoints
- Managed Identity for secure authentication with Key Vault
- RBAC for Key Vault access control
- CORS configuration to limit cross-origin requests
- Diagnostic logging for security auditing

## Prerequisites

- Azure subscription
- Azure CLI installed (`az`)
- Azure Developer CLI installed (`azd`)
- Node.js 20+ and npm

## Deployment Options

### Option 1: Using Azure Developer CLI (Recommended)

1. **Login to Azure**

   ```zsh
   az login
   ```

2. **Select your subscription**

   ```zsh
   az account set --subscription <your-subscription-id>
   ```

3. **Initialize the Azure environment**

   ```zsh
   azd init
   ```

4. **Deploy the application**

   ```zsh
   azd up
   ```

   This will:
   - Provision all Azure resources defined in the Bicep templates
   - Build the application code
   - Deploy the application to the provisioned resources

### Option 2: Manual Deployment with Azure CLI

1. **Login to Azure**

   ```zsh
   az login
   ```

2. **Select your subscription**

   ```zsh
   az account set --subscription <your-subscription-id>
   ```

3. **Create a resource group**

   ```zsh
   az group create --name octocat-supply-rg --location eastus
   ```

4. **Deploy the Bicep template**

   ```zsh
   az deployment group create \
     --resource-group octocat-supply-rg \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.json
   ```

5. **Build and deploy the API**

   ```zsh
   # Build the API
   npm run build --workspace=api
   
   # Deploy to App Service
   az webapp deployment source config-zip \
     --resource-group octocat-supply-rg \
     --name <app-service-name> \
     --src api/dist/api.zip
   ```

6. **Build and deploy the Frontend**

   ```zsh
   # Build the frontend
   npm run build --workspace=frontend
   
   # Deploy to Static Web App
   az staticwebapp deploy \
     --resource-group octocat-supply-rg \
     --name <static-web-app-name> \
     --source frontend/dist
   ```

### Option 3: GitHub Actions CI/CD (Automated)

1. **Create the following secrets in your GitHub repository**:
   - `AZURE_CLIENT_ID`: Azure service principal client ID
   - `AZURE_TENANT_ID`: Azure tenant ID
   - `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

2. **Create a service principal** (if you don't have one already):

   ```zsh
   az ad sp create-for-rbac --name "OctoCATSupply" --role contributor \
     --scopes /subscriptions/<subscription-id> \
     --json-auth
   ```

3. **Push to the main branch** to trigger the deployment workflow or use the manual trigger in GitHub Actions.

## Customizing the Deployment

Edit the `infra/main.parameters.json` file to customize your deployment:

- `baseName`: Base name for all Azure resources
- `environmentName`: Environment name (dev, test, prod)
- `location`: Azure region for deployment
- `useRbacAuthorization`: Whether to use RBAC for Key Vault (recommended)
- `appServicePlanSku`: SKU for App Service Plan
- `staticWebAppSku`: SKU for Static Web App ('Free' or 'Standard')

## Post-Deployment Configuration

### 1. Configure Environment-Specific Settings

For the API backend:
```zsh
az webapp config appsettings set \
  --resource-group octocat-supply-rg \
  --name <app-service-name> \
  --settings "NODE_ENV=production"
```

For the frontend:
```zsh
az staticwebapp appsettings set \
  --resource-group octocat-supply-rg \
  --name <static-web-app-name> \
  --setting-names "VITE_API_URL=https://<app-service-url>"
```

### 2. Configure Custom Domain (Optional)

For the API backend:
```zsh
az webapp config hostname add \
  --resource-group octocat-supply-rg \
  --webapp-name <app-service-name> \
  --hostname api.your-domain.com
```

For the frontend in Static Web App:
```zsh
az staticwebapp hostname set \
  --resource-group octocat-supply-rg \
  --name <static-web-app-name> \
  --hostname www.your-domain.com
```

## Troubleshooting

### Common Issues

1. **Deployment fails with permission errors**:
   - Ensure your service principal has the correct permissions
   - Check the role assignments for the managed identity

2. **API and Frontend cannot communicate**:
   - Verify CORS settings in the App Service configuration
   - Check that the frontend is using the correct API URL

3. **Key Vault access denied**:
   - Ensure the managed identity has been granted access to Key Vault
   - Check the RBAC role assignments if using RBAC authentication

### Viewing Logs

For App Service logs:
```zsh
az webapp log tail \
  --resource-group octocat-supply-rg \
  --name <app-service-name>
```

For Static Web App logs, view them in the Azure Portal under the Monitoring section.

## Security Best Practices

1. **Rotate credentials regularly**
2. **Enable Azure Defender for all services**
3. **Implement IP restrictions for App Service if appropriate**
4. **Enable Key Vault purge protection for production environments**
5. **Set up alerting for suspicious activities**

## Additional Resources

- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Static Web Apps Documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
