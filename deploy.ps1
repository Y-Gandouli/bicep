Connect-AzAccount -Tenant '5c7d1d04-7088-43ad-a984-f402741acef1'
Select-AzSubscription -Subscription 'd02e23ef-ebce-4dd2-b855-5f48475f67ca'
New-AzResourceGroupDeployment -Name 'mouaad'  -ResourceGroupName 'myresourceg' -TemplateFile './main.bicep' -TemplateParameterFile .\main.parameters.json