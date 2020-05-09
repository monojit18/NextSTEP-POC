param([Parameter(Mandatory=$false)] [string] $resourceGroup = "AKSDev-rg",
        [Parameter(Mandatory=$false)] [string] $vnetResourceGroup = "infraservices-nextstep-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "nextstep-dev-cluster",
        [Parameter(Mandatory=$false)] [string] $primaryOwnerKey = "primary_owner",
        [Parameter(Mandatory=$false)] [string] $primaryOwnerValue = "vijay.vm@mphasis.com",
        [Parameter(Mandatory=$false)] [string] $projectCodeKey = "project_code",
        [Parameter(Mandatory=$false)] [string] $projectCodeValue = "96278",
        [Parameter(Mandatory=$false)] [string] $projectNameKey = "project_name",
        [Parameter(Mandatory=$false)] [string] $projectNameValue = "Service Transformation Platform",
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $userEmail = "nextstepreview.user@mphasis.com",        
        [Parameter(Mandatory=$false)] [string] $acrName = "nxtstpacr",        
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "nextstep-dev-kv",
        [Parameter(Mandatory=$false)] [string] $appgwName = "nextstep-dev-appgw",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "nextstep-vnet",
        [Parameter(Mandatory=$false)] [string] $acrTemplateFileName = "nextstep-acr-deploy",
        [Parameter(Mandatory=$false)] [string] $keyVaultTemplateFileName = "nextstep-keyvault-deploy",
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "e5d4143d-aa29-4479-8588-405f723c89f5",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/Users/monojitdattams/Development/Projects/Workshops/Mphasis_Workshop/NextSTEP-POC/Deployments")

$projectName = "nextstep-dev"
$vnetRole = "Network Contributor"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$acrSPIdName = $acrName + "-sp-id"
$acrSPSecretName = $acrName + "-sp-secret"
$certSecretName = $appgwName + "-cert-secret"
$logWorkspaceName = $projectName + "-lw"
$templatesFolderPath = $baseFolderPath + "/Templates"
$certPFXFilePath = $baseFolderPath + "/Certs/nextstep-dev.pfx"

# Assuming Logged In

# GET ObjectID
$loggedInUser = Get-AzADUser -UserPrincipalName $userEmail
$objectId = $loggedInUser.Id
Write-Host "ObjectId:$objectId"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$resourceG = Get-AzResourceGroup -Name $resourceGroup -Location $location
if (!$resourceG)
{
   
   $tagRef = @{$primaryOwnerKey=$primaryOwnerValue; $projectCodeKey=$projectCodeValue; $projectNameKey=$projectNameValue;}
   $resourceG = New-AzResourceGroup -Name $resourceGroup `
   -Location $location -Tag $tagRef
   if (!$resourceG)
   {
        Write-Host "Error creating Resource Group"
        return;
   }

}

$logWorkspace = Get-AzOperationalInsightsWorkspace `
-ResourceGroupName $resourceGroup `
-Name $logWorkspaceName 
if (!$logWorkspace)
{
   
   $logWorkspace = New-AzOperationalInsightsWorkspace `
   -ResourceGroupName $resourceGroup `
   -Location $location -Name $logWorkspaceName
   if (!$logWorkspace)
   {
        Write-Host "Error creating Resource Group"
        return;
   }
}

$aksSP = New-AzADServicePrincipal -SkipAssignment
if (!$aksSP)
{

    Write-Host "Error creating Service Principal for AKS"
    return;

}

Write-Host $aksSP.DisplayName
Write-Host $aksSP.Id
Write-Host $aksSP.ApplicationId

$acrSP = New-AzADServicePrincipal -SkipAssignment
if (!$acrSP)
{

    Write-Host "Error creating Service Principal for ACR"
    return;

}

Write-Host $acrSP.DisplayName
Write-Host $acrSP.Id
Write-Host $acrSP.ApplicationId

# Deploy ACR
$acrDeployCommand = "/ACR/$acrTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $acrTemplateFileName -acrName $acrName"
$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

# Deploy KeyVault
$keyVaultDeployCommand = "/KeyVault/$keyVaultTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $keyVaultTemplateFileName -keyVaultName $keyVaultName -objectId $objectId"
$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

# Read Certificate (AppGW SSL)
$certBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
$certContents = [Convert]::ToBase64String($certBytes)
$certContentsSecure = ConvertTo-SecureString -String $certContents -AsPlainText -Force

$aksSPObjectId = ConvertTo-SecureString -String $aksSP.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPIdName `
-SecretValue $aksSPObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPSecretName `
-SecretValue $aksSP.Secret

$acrSPObjectId = ConvertTo-SecureString -String $acrSP.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPIdName `
-SecretValue $acrSPObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPSecretName `
-SecretValue $acrSP.Secret

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName `
-SecretValue $certContentsSecure

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $vnetResourceGroup
if ($aksVnet)
{

    Write-Host "AKS Id:$aksVnet.Id"
    New-AzRoleAssignment -ApplicationId $aksSP.ApplicationId `
    -Scope $aksVnet.Id -RoleDefinitionName $vnetRole

}

$acrInfo = Get-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup
if ($acrInfo)
{

    Write-Host "ACR Id:$acrInfo.Id"
    New-AzRoleAssignment -ApplicationId $acrSP.ApplicationId `
    -Scope $acrInfo.Id -RoleDefinitionName acrpush

}

Write-Host "Pre-Config Successfully Done!"
