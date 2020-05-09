param([Parameter(Mandatory=$false)] [string] $resourceGroup = "AKSDev-rg",        
        [Parameter(Mandatory=$false)] [string] $clusterName = "nextstep-dev-cluster",
        [Parameter(Mandatory=$false)] [string] $spIdName = "nextstep-dev-sp-id",
        [Parameter(Mandatory=$false)] [string] $acrName = "nxtstpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "nextstep-dev-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "nextstep-dev-vnet",        
        [Parameter(Mandatory=$false)] [string] $appgwName = "nextstep-dev-appgw",
        [Parameter(Mandatory=$false)] [string] $logWorkspaceName = "nextstep-dev-lw",
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "e5d4143d-aa29-4479-8588-405f723c89f5")

$publicIpAddressName = "$appgwName-pip"
$subscriptionCommand = "az account set -s $subscriptionId"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

az aks delete --name $clusterName --resource-group $resourceGroup --yes

Remove-AzApplicationGateway -Name $appgwName `
-ResourceGroupName $resourceGroup -Force

Remove-AzPublicIpAddress -Name $publicIpAddressName `
-ResourceGroupName $resourceGroup -Force

Remove-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup `
-VaultName $keyVaultName
if ($keyVault)
{

    $spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName `
    -Name $spIdName
    if ($spAppId)
    {

        Remove-AzADServicePrincipal `
        -ApplicationId $spAppId.SecretValueText -Force
        
    }

    Remove-AzKeyVault -InputObject $keyVault -Force

}

Remove-AzOperationalInsightsWorkspace `
-ResourceGroupName $resourceGroup `
-Name $logWorkspaceName -Force

Write-Host "Remove Successfully Done!"