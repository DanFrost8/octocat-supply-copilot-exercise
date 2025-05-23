#!/bin/bash
# deploy.sh - Helper script for deploying OctoCAT Supply Chain to Azure

# Exit on error
set -e

# Default values
LOCATION="eastus"
ENVIRONMENT="dev"
RESOURCE_GROUP=""
CREATE_RESOURCE_GROUP=true
SKIP_BUILD=false

# Display help
show_help() {
  echo "Usage: ./deploy.sh [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help                  Show this help message"
  echo "  -l, --location LOCATION     Azure region to deploy to (default: eastus)"
  echo "  -e, --environment ENV       Environment name: dev, test, prod (default: dev)"
  echo "  -g, --resource-group NAME   Use existing resource group instead of creating one"
  echo "  --skip-build                Skip building the application"
  echo ""
  echo "Examples:"
  echo "  ./deploy.sh                                # Deploy with default settings"
  echo "  ./deploy.sh -e prod -l westus2             # Deploy to production in westus2"
  echo "  ./deploy.sh -g my-existing-resource-group  # Use existing resource group"
  exit 0
}

# Parse command-line options
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      show_help
      ;;
    -l|--location)
      LOCATION="$2"
      shift
      shift
      ;;
    -e|--environment)
      ENVIRONMENT="$2"
      shift
      shift
      ;;
    -g|--resource-group)
      RESOURCE_GROUP="$2"
      CREATE_RESOURCE_GROUP=false
      shift
      shift
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

# Set resource group name if not provided
if [[ -z "$RESOURCE_GROUP" ]]; then
  RESOURCE_GROUP="octocat-supply-$ENVIRONMENT-rg"
fi

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
  echo "Error: Azure CLI is not installed. Please install it first."
  echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit 1
fi

# Check if logged in to Azure
echo "Checking Azure login..."
ACCOUNT=$(az account show --query name -o tsv 2>/dev/null || echo "")
if [[ -z "$ACCOUNT" ]]; then
  echo "You are not logged in to Azure. Please log in now."
  az login
fi

# Show current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Using subscription: $SUBSCRIPTION ($SUBSCRIPTION_ID)"
echo "Press Enter to continue or Ctrl+C to cancel..."
read

# Create resource group if needed
if [[ "$CREATE_RESOURCE_GROUP" = true ]]; then
  echo "Creating resource group: $RESOURCE_GROUP in $LOCATION..."
  az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
else
  echo "Using existing resource group: $RESOURCE_GROUP"
  # Check if resource group exists
  if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo "Error: Resource group $RESOURCE_GROUP does not exist."
    exit 1
  fi
fi

# Build the application (if not skipped)
if [[ "$SKIP_BUILD" = false ]]; then
  echo "Building API..."
  npm run build --workspace=api

  echo "Building Frontend..."
  npm run build --workspace=frontend
fi

# Deploy Bicep template
echo "Deploying infrastructure with Bicep..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json \
  --parameters environmentName="$ENVIRONMENT" location="$LOCATION"

# Get deployment outputs
echo "Getting deployment outputs..."
API_URL=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "main" \
  --query "properties.outputs.apiServiceUrl.value" \
  --output tsv)

FRONTEND_URL=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "main" \
  --query "properties.outputs.frontendUrl.value" \
  --output tsv)

KEY_VAULT_NAME=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "main" \
  --query "properties.outputs.keyVaultName.value" \
  --output tsv)

APP_SERVICE_NAME=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "main" \
  --query "properties.outputs.appServiceName.value" \
  --output tsv || echo "")

STATIC_WEB_APP_NAME=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "main" \
  --query "properties.outputs.staticWebAppName.value" \
  --output tsv || echo "")

# Deploy application code
if [[ ! -z "$APP_SERVICE_NAME" ]]; then
  echo "Deploying API code to App Service..."
  # Create a ZIP file from the API build
  (cd api && zip -r ../api.zip dist package.json package-lock.json)
  
  # Deploy to App Service
  az webapp deployment source config-zip \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_SERVICE_NAME" \
    --src api.zip
    
  # Clean up ZIP file
  rm api.zip
fi

if [[ ! -z "$STATIC_WEB_APP_NAME" ]]; then
  echo "Deploying Frontend code to Static Web App..."
  az staticwebapp deploy \
    --resource-group "$RESOURCE_GROUP" \
    --name "$STATIC_WEB_APP_NAME" \
    --source frontend/dist \
    --api-location ""
fi

# Display deployment information
echo ""
echo "====== Deployment Complete ======"
echo "Environment: $ENVIRONMENT"
echo "Resource Group: $RESOURCE_GROUP"
echo ""
echo "API URL: $API_URL"
echo "Frontend URL: $FRONTEND_URL"
echo "Key Vault: $KEY_VAULT_NAME"
echo ""
echo "To clean up resources when no longer needed, run:"
echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo "================================="
