targetScope = 'resourceGroup'

param location string = 'eastus2'
param appServicePlanName string = 'bicepAppPlan'
param webAppName string = 'bps-bicep-webapp-11252026'
param storageAccountName string = 'biceplabstorage11252026'
param sqlServerName string = 'bps-bicep-sqlserver-11252026'
param sqlDatabaseName string = 'bicepdb'
param sqlAdminUser string
@secure()
param sqlAdminPassword string


resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource appPlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  properties: {
    perSiteScaling: false
    maximumElasticWorkerCount: 10
  }
}

resource autoscaleSetting 'Microsoft.Insights/autoscaleSettings@2022-10-01' = {
  name: 'autoscale-rule'
  location: location
  properties: {
    enabled: true
    targetResourceUri: resourceId('Microsoft.Web/serverfarms', appServicePlanName)
    profiles: [
    {
      name: 'defaultProfile'
      capacity: {
        minimum: '1'
        maximum: '5'
        default: '1'
      }
      rules: [
        {
          metricTrigger: {
            metricName: 'CpuPercentage'
            metricResourceUri: resourceId('Microsoft.Web/serverfarms', appServicePlanName)
            operator: 'GreaterThan'
            threshold: 75
            timeAggregation: 'Average'
            statistic: 'Average'
            timeWindow: 'PT5M'
            timeGrain: 'PT1M'
          }
          scaleAction: {
            direction: 'Increase'
            type: 'ChangeCount'
            value: '1'
            cooldown: 'PT1M'
          }
        }
      ]
    }
  ]
  }
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appPlan.id
  }
}

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUser
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: sqlDatabaseName
  location: location
  parent: sqlServer
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
}
