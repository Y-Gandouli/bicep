param location string
param adname string
param psw string
param vnetParams object
param fileShareParams object
param storageParams object
param virtualMachineParams object
param SqlServerParams object
param mywebappParams object
param nsgParams object
param SqlFirewallRUles1Params object
param SqlFirewallRUles2Params object
param sqlDatabaseParams object


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
          addressPrefix: subnet.addressPrefix
        }
    }]
    enableDdosProtection: vnetParams.enableDdosProtection
  }
} 

/*resource myStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  
  name: storageParams.name
  location: location
  sku: {
    name: storageParams.skuName
  }
  kind: storageParams.kind
  properties: { 
    accessTier: storageParams.accessTier
  }
  
}*/

module myStorage './storageAccount.bicep' = {
  scope: resourceGroup()
  
  name: 'storagedep'
  params: {
    name : storageParams.name
    location: location
    skuName: storageParams.skuName
    kind: storageParams.kind
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
    
  }
}

resource nsg1 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  
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

// Hadi w li moraha, rdhom array b for
resource SqlServerFirewallRUles1 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
 
  name: SqlFirewallRUles1Params.name
  parent: SqlServer
  
  properties: {
    startIpAddress: SqlFirewallRUles1Params.startIpAddress
    endIpAddress: SqlFirewallRUles1Params.endIpAddress

  }
}

resource SqlServerFirewallRUles2 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  name: SqlFirewallRUles2Params.name
  parent: SqlServer
  
  properties: {
    startIpAddress: SqlFirewallRUles2Params.startIpAddress
    endIpAddress: SqlFirewallRUles2Params.endIpAddress

  }
}

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
    collation: sqlDatabaseParams.collation
    maxSizeBytes: sqlDatabaseParams.maxSizeBytes
    catalogCollation: sqlDatabaseParams.catalogCollation
    zoneRedundant: sqlDatabaseParams.zoneRedundant
    readScale: sqlDatabaseParams.readScale
    autoPauseDelay: sqlDatabaseParams.autoPauseDelay
    requestedBackupStorageRedundancy: sqlDatabaseParams.requestedBackupStorageRedundancy
    availabilityZone: sqlDatabaseParams.availabilityZone
  }
  

}


 // Hadi app service, mais makatreferencer 7ta app plan.
resource mywebapp 'Microsoft.Web/sites@2023-01-01' = {
  
  name: mywebappParams.name
  location: location
  identity: mywebappParams.identity 
  kind: mywebappParams.kind 
  
  properties:{
    enabled: true
    publicNetworkAccess: mywebappParams.publicNetworkAccess
    redundancyMode: mywebappParams.redundancyMode
    
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
