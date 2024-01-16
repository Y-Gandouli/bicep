Connect-AzAccount -Tenant 'bb5218c1-1d99-4da3-a809-dd35f630016d'
Select-AzSubscription -Subscription '41b9910a-eab0-459e-88e4-59b0dc35b335'
New-AzResourceGroupDeployment -Name 'mouaad6'  -ResourceGroupName 'myResourceGroup' -TemplateFile './main.bicep' `
-TemplateParameterFile './main.parameters.json' -whatIf
