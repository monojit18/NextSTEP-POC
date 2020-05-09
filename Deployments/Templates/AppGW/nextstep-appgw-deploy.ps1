param([Parameter(Mandatory=$false)] [string] $rg,
        [Parameter(Mandatory=$false)] [string] $vnetResourceGroup,
        [Parameter(Mandatory=$false)] [string] $fpath,
        [Parameter(Mandatory=$false)] [string] $deployFileName,
        [Parameter(Mandatory=$false)] [string] $appgwName,
        [Parameter(Mandatory=$false)] [string] $vnetName,
        [Parameter(Mandatory=$false)] [string] $subnetName,
        [Parameter(Mandatory=$false)] [string] $backendIPAddress)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/$deployFileName.json" `
-TemplateParameterFile "$fpath/AppGW/$deployFileName.parameters.json" `
-vnetResourceGroup $vnetResourceGroup `
-applicationGatewayName $appgwName `
-vnetName $vnetName -subnetName $subnetName `
-backendIpAddress1 $backendIPAddress

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/$deployFileName.json" `
-TemplateParameterFile "$fpath/AppGW/$deployFileName.parameters.json" `
-vnetResourceGroup $vnetResourceGroup `
-applicationGatewayName $appgwName `
-vnetName $vnetName -subnetName $subnetName `
-backendIpAddress1 $backendIPAddress