param([Parameter(Mandatory=$true)] [string] $mode,
        [Parameter(Mandatory=$false)] [string] $resourceGroup,
        [Parameter(Mandatory=$false)] [string] $clusterName,
        [Parameter(Mandatory=$false)] [string] $primaryOwnerKey,
        [Parameter(Mandatory=$false)] [string] $primaryOwnerValue,
        [Parameter(Mandatory=$false)] [string] $projectCodeKey,
        [Parameter(Mandatory=$false)] [string] $projectCodeValue,
        [Parameter(Mandatory=$false)] [string] $projectNameKey,
        [Parameter(Mandatory=$false)] [string] $projectNameValue,
        [Parameter(Mandatory=$false)] [string] $location,
        [Parameter(Mandatory=$false)] [string] $acrName,
        [Parameter(Mandatory=$false)] [string] $keyVaultName,
        [Parameter(Mandatory=$false)] [string] $aksVNetName,
        [Parameter(Mandatory=$false)] [string] $vnetResourceGroup,
        [Parameter(Mandatory=$false)] [string] $aksSubnetName,
        [Parameter(Mandatory=$false)] [string] $version,
        [Parameter(Mandatory=$false)] [string] $addons,
        [Parameter(Mandatory=$false)] [string] $nodeCount,
        [Parameter(Mandatory=$false)] [string] $minNodeCount,
        [Parameter(Mandatory=$false)] [string] $maxNodeCount,
        [Parameter(Mandatory=$false)] [string] $maxPods,
        [Parameter(Mandatory=$false)] [string] $vmSetType,
        [Parameter(Mandatory=$false)] [string] $nodeVMSize,
        [Parameter(Mandatory=$false)] [string] $networkPlugin,
        [Parameter(Mandatory=$false)] [string] $networkPolicy,
        [Parameter(Mandatory=$false)] [string] $nodePoolName,
        [Parameter(Mandatory=$false)] [string] $aadServerAppID,
        [Parameter(Mandatory=$false)] [string] $aadServerAppSecret,
        [Parameter(Mandatory=$false)] [string] $aadClientAppID,
        [Parameter(Mandatory=$false)] [string] $aadTenantID)

$projectName = "nextstep-dev"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$logWorkspaceName = $projectName + "-lw"

$tags = "$primaryOwnerKey=$primaryOwnerValue $projectCodeKey=$projectCodeValue $projectNameKey=$projectNameValue"
Write-Host $tags

$logWorkspace = Get-AzOperationalInsightsWorkspace `
-ResourceGroupName $resourceGroup `
-Name $logWorkspaceName
if (!$logWorkspace)
{

    Write-Host "Error fetching Log Workspace"
    return;

}

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup `
-VaultName $keyVaultName
if (!$keyVault)
{

    Write-Host "Error fetching KeyVault"
    return;

}

$spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $aksSPIdName
if (!$spAppId)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$spPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $aksSPSecretName
if (!$spPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $vnetResourceGroup
if (!$aksVnet)
{

    Write-Host "Error fetching Vnet"
    return;

}

$aksSubnet = Get-AzVirtualNetworkSubnetConfig -Name $aksSubnetName `
-VirtualNetwork $aksVnet
if (!$aksSubnet)
{

    Write-Host "Error fetching Subnet"
    return;

}

if ($mode -eq "create")
{

    az aks create --name $clusterName --resource-group $resourceGroup `
    --kubernetes-version $version --enable-addons $addons --location $location `
    --vnet-subnet-id $aksSubnet.Id --node-vm-size $nodeVMSize `
    --node-count $nodeCount --max-pods $maxPods `
    --service-principal $spAppId.SecretValueText `
    --client-secret $spPassword.SecretValueText `
    --network-plugin $networkPlugin --network-policy $networkPolicy `
    --nodepool-name $nodePoolName --vm-set-type $vmSetType `
    --generate-ssh-keys `
    --aad-client-app-id $aadClientAppID `
    --aad-server-app-id $aadServerAppID `
    --aad-server-app-secret $aadServerAppSecret `
    --aad-tenant-id $aadTenantID `
    --tags $tags `
    --workspace-resource-id $logWorkspace.ResourceId
    
}
elseif ($mode -eq "update")
{

    az aks nodepool update --cluster-name $clusterName `
    --resource-group $resourceGroup --enable-cluster-autoscaler `
    --min-count $minNodeCount --max-count $maxNodeCount `
    --name $nodePoolName

    # az aks update-credentials --name $clusterName --resource-group $resourceGroup `
    # --reset-aad `
    # --aad-client-app-id $aadClientAppID `
    # --aad-server-app-id $aadServerAppID `
    # --aad-server-app-secret $aadServerAppSecret `
    # --aad-tenant-id $aadTenantID

    
}
# elseif ($mode -eq "scale")
# {

#     az aks nodepool scale --cluster-name $clusterName --resource-group $resourceGroup `
#     --node-count $nodeCount --name $nodePoolName
    
# }

Write-Host "Cluster Successfully Done!"

