// HomeFinance — App Service (Linux) + plan, system-assigned identity.
// RG is created by the one-time bootstrap (infra/bootstrap.md), NOT by this template,
// so the CI principal stays least-privilege (scoped to the RG).
targetScope = 'resourceGroup'

@description('Logical app name used in resource names.')
param appName string = 'homefinance'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('App Service Plan SKU. F1 (Free) for the first smoke test; switch to B1 to enable Always On / WebSockets.')
param skuName string = 'F1'

@description('Environment moniker baked into resource names.')
param environmentName string = 'prod'

// azurewebsites.net is a global namespace — append a deterministic token for uniqueness.
var resourceToken = uniqueString(resourceGroup().id)
var webAppName = 'app-${appName}-${environmentName}-${resourceToken}'
var planName = 'plan-${appName}-${environmentName}'
var isFree = skuName == 'F1'

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: {
    name: skuName
    tier: isFree ? 'Free' : 'Basic'
  }
  properties: {
    reserved: true // mandatory for Linux plans
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned' // provision now so Key Vault drops in later
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: isFree ? false : true // F1 REQUIRES false or the deploy fails
      webSocketsEnabled: false // F1; flip to true at B1+ for Blazor Server
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      healthCheckPath: '/healthz'
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'false'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
    }
  }
}

output webAppName string = webApp.name
output webAppDefaultHostname string = webApp.properties.defaultHostName
