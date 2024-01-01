param name string
param location string
param skuName string
param kind string
param accessTier string


resource myStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  
  name: name
  location: location
  sku: {
    name: skuName
  }
  kind: kind
  properties: { 
    accessTier: accessTier
  }
  
}
