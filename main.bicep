@description('The location of the resources using this parameter')
param location string
@description('the database administrators name')
param adname string
@secure()
@minLength(6)
param psw string
@metadata({
  name: 'string.the name of vn'
  addressPrefixes: ''
  enableDdosProtection: 'bool'
  subnets:[{
    name: 'subname'
    addressPrefix: 'the add'
}]
})
param vnetParams object
@metadata({
  accessTier:'string. you can choose either Premium, Transaction Optimized, Hot or Cool'
  protocol: 'string. NFS or SMB'
})
param fileShareParams object
param storageParams object
param virtualMachineParams object
param SqlServerParams object
param mywebappParams object
param nsgParams object
param SqlFirewallRUles object
param sqlDatabaseParams object
param appServicePlanParams object

resource ipAddress 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: 'vmIpAdd'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    deleteOption: 'Delete'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource netInterface 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: 'netInterfae'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfigName'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: ipAddress.id
          }
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
 
  name: vnetParams.name
  location: location
  
  properties: {
    addressSpace: {
      addressPrefixes: vnetParams.addressPrefixes   
    }
    subnets: [ for subnet in vnetParams.subnets : {
        name: subnet.name
        properties: { 
         /* delegations: [{
            name: vnetParams.dName1
            properties: {
              serviceName: 'Microsoft.Web/serverFarms'
            }
         },{
            name: vnetParams.dName2
            properties: {
              serviceName: 'Microsoft.Network/virtualNetworks'
            }
        }
      ]*/
          addressPrefix: subnet.addressPrefix
        }
    }]
  }
}

resource myStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  
  name: storageParams.storageName
  location: location
  sku: {
    name: storageParams.skuName
  }
  kind: storageParams.kind
  properties: { 
    accessTier: storageParams.accessTier
  }
  
}

resource myfiles 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  
  name: '${myStorage.name}/default/${fileShareParams.name}'
  properties: {
    accessTier: fileShareParams.accessTier
    enabledProtocols: fileShareParams.protocol
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  
  name: virtualMachineParams.name 
  location: location
  properties: {
      hardwareProfile: { vmSize: virtualMachineParams.size }
      storageProfile:{
        imageReference: {
          publisher: virtualMachineParams.publisher 
          offer: virtualMachineParams.offer 
          sku: virtualMachineParams.sku 
          version: virtualMachineParams.version 
        }
        osDisk:{
          name: virtualMachineParams.osDiskName 
          osType: virtualMachineParams.osType 
          createOption: virtualMachineParams.createOption 
          caching: virtualMachineParams.caching 
          deleteOption: virtualMachineParams.deleteOption 
        }
      }
      osProfile:{
        computerName: virtualMachineParams.computerName
        adminUsername: adname
        adminPassword: psw
      }
      networkProfile: { 
         
          networkInterfaces: [{
            id: netInterface.id
            properties: {
              deleteOption: 'Delete'
            }
          }]
      }
  }
}

resource nsgRules 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  
  name: nsgParams.name
  location: location
  properties:{
    securityRules:[ for nsgRule in nsgParams.nsgRules : { 
        name: nsgRule.name
        type: nsgRule.type
        
        properties: {
          access: nsgRule.access
          direction: nsgRule.direction
          priority:  nsgRule.priority
          protocol: nsgRule.protocol
          sourceAddressPrefix: nsgRule.sourceAddressPrefix
          sourceAddressPrefixes: nsgRule.sourceAddressPrefixes
          destinationAddressPrefixes: nsgRule.destinationAddressPrefixes
          sourcePortRange: nsgRule.sourcePortRange
          destinationPortRange: nsgRule.destinationPortRange
        }
      }
    ]
  }
}

resource SqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  
  name: SqlServerParams.name 
  location: location

  properties: {
    administratorLogin: adname
    administratorLoginPassword: psw
    minimalTlsVersion: SqlServerParams.minimalTlsVersion
    publicNetworkAccess: SqlServerParams.publicNetworkAccess
  }
}

resource SqlServerFirewallRUles 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = [ 
  
  for rule in SqlFirewallRUles.rules: {
    name: rule.name
    parent: SqlServer
  
    properties: {
      startIpAddress: rule.startIpAddress
      endIpAddress: rule.endIpAddress
    }
  } 
]

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: sqlDatabaseParams.name
  location: location
  parent: SqlServer
  sku: {
    name: sqlDatabaseParams.skuName
    tier: sqlDatabaseParams.tier
    family: sqlDatabaseParams.family
    capacity: sqlDatabaseParams.capacity
  }
  properties: {

    zoneRedundant: sqlDatabaseParams.zoneRedundant
    autoPauseDelay: sqlDatabaseParams.autoPauseDelay
    requestedBackupStorageRedundancy: sqlDatabaseParams.requestedBackupStorageRedundancy
    availabilityZone: sqlDatabaseParams.availabilityZone
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanParams.name
  location: location
  kind: appServicePlanParams.kind
  properties: {
    reserved: appServicePlanParams.reserved
  }
  sku: {
    name: appServicePlanParams.skuName
    tier: appServicePlanParams.tier
    family: appServicePlanParams.family
    size: appServicePlanParams.size
    capacity: appServicePlanParams.capacity
  }
}

resource mywebapp 'Microsoft.Web/sites@2023-01-01' = {
  
  name: mywebappParams.name
  location: location
  kind: mywebappParams.kind 
  
  properties:{
    enabled: true
    publicNetworkAccess: mywebappParams.publicNetworkAccess
    redundancyMode: mywebappParams.redundancyMode
    serverFarmId: appServicePlan.id
    hostNameSslStates: [
      {
      name: mywebappParams.hostName
      sslState: mywebappParams.sslState
      hostType: mywebappParams.hostType
      }
      {
      name: mywebappParams.hostNameScm
      sslState: mywebappParams.sslStateScm
      hostType: mywebappParams.hostTypeScm
      }
    ]

    reserved: mywebappParams.reserved
    httpsOnly: mywebappParams.httpsOnly
    keyVaultReferenceIdentity: mywebappParams.keyVaultReferenceIdentity

    virtualNetworkSubnetId: filter(virtualNetwork.properties.subnets, x => x.name == 'sub1')[0].id
    
    siteConfig: {
      numberOfWorkers: mywebappParams.numberOfWorkers
      linuxFxVersion: mywebappParams.linuxFxVersion
      netFrameworkVersion: mywebappParams.netFrameworkVersion
      scmType: mywebappParams.scmType 
      logsDirectorySizeLimit: mywebappParams.logsDirectorySizeLimit
      alwaysOn: mywebappParams.alwaysOn
      appCommandLine: mywebappParams.appCommandLine
      managedPipelineMode: mywebappParams.managedPipelineMode
      remoteDebuggingVersion: mywebappParams.remoteDebuggingVersion

      azureStorageAccounts: {
        mount: {
          type: 'AzureFiles'
          accountName: '${myStorage.name}'
          shareName: '${fileShareParams.name}'
          mountPath: '/uploads'
      }
      }
    }

  }
}
