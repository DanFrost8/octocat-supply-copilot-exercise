#!/bin/bash
# azd-deploy.sh - Helper script for deploying with Azure Developer CLI

# Exit on error
set -e

# Default values
ENVIRONMENT="dev"

# Display help
show_help() {
  echo "Usage: ./azd-deploy.sh [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help               Show this help message"
  echo "  -e, --environment ENV    Environment to deploy to: dev, test, prod (default: dev)"
  echo ""
  echo "Examples:"
  echo "  ./azd-deploy.sh                # Deploy to dev environment"
  echo "  ./azd-deploy.sh -e test        # Deploy to test environment"
  echo "  ./azd-deploy.sh -e prod        # Deploy to production environment"
  exit 0
}

# Parse command-line options
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      show_help
      ;;
    -e|--environment)
      ENVIRONMENT="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "test" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Error: Environment must be 'dev', 'test', or 'prod'"
  exit 1
fi

# Check if azd is installed
if ! command -v azd &> /dev/null; then
  echo "Error: Azure Developer CLI (azd) is not installed."
  echo "Visit: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd"
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

# Select environment
echo "Using environment: $ENVIRONMENT"
ENV_FILE=".azure/${ENVIRONMENT}-environment.yaml"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: Environment file $ENV_FILE not found."
  exit 1
fi

# Initialize Azure Developer CLI environment
echo "Initializing Azure Developer CLI environment..."
azd env new octocat-supply-$ENVIRONMENT --no-prompt || true
azd env select octocat-supply-$ENVIRONMENT

# Set environment configuration
echo "Loading environment configuration from $ENV_FILE..."
azd env refresh -e "$ENV_FILE"

# Provision Azure resources
echo "Provisioning Azure resources..."
azd provision

# Deploy application
echo "Deploying application..."
azd deploy

# Display deployment information
echo ""
echo "====== Deployment Complete ======"
echo "Environment: $ENVIRONMENT"
echo ""
echo "Use the following command to get the deployment URLs:"
echo "azd env get-values"
echo "================================="
