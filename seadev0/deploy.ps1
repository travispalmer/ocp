<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER deploymentName
    The deployment name.

 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

 .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
#>

param(
 [Parameter(Mandatory=$False)]
 [string]
 $resourceGroupName="ocp-seadev0-rg",

 [string]
 $resourceGroupLocation="southeastasia",

 [Parameter(Mandatory=$false)]
 [string]
 $deploymentName="OCP_deployment_" + (Get-Date).ToString(),

 [string]
 $templateFilePath = "azuredeploy.json",

 [string]
 $parametersFilePath = "azuredeploy.parameters.json",

 [string]
 $ServiceAppName = "OCPApp"
)

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# sign in
#Write-Host "Logging in...";
#Login-AzureRm;

# select subscription
#Write-Host "Selecting subscription '$subscriptionId'";
#Select-AzureRmSubscription -SubscriptionID $subscriptionId;

# Register RPs
# $resourceProviders = @("microsoft.network","microsoft.storage","microsoft.compute","microsoft.resources");
# if($resourceProviders.length) {
#     Write-Host "Registering resource providers"
#     foreach($resourceProvider in $resourceProviders) {
#         RegisterRP($resourceProvider);
#     }
# }

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

if($ServiceAppName -ne "")
{
    $app = Get-AzureRmADApplication -DisplayName $ServiceAppName
    if($app -eq $null)
    {
        $app = New-AzureRmADApplication -DisplayName $ServiceAppName -HomePage "https://localhost:8080" -IdentifierUris "https://localhost:8080"
        Add-Type -Assembly System.Web
        $securePassword = [System.Web.Security.Membership]::GeneratePassword(16,3) | ConvertTo-SecureString -Force -AsPlainText
        New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId -DisplayName $ServiceAppName -Password $securePassword -Scope $resourceGroup.ResourceId
    }

    $servicePrincipal = Get-AzureRmADServicePrincipal -DisplayNameBeginsWith $ServiceAppName
    $role = Get-AzureRmRoleAssignment -ObjectId $servicePrincipal.Id -ResourceGroupName $resourceGroupName
    if($role.RoleDefinitionName -eq "Contributor")
    {
        Remove-AzureRmRoleAssignment -ObjectId $servicePrincipal.Id -ResourceGroupName $resourceGroupName -RoleDefinitionName $role.RoleDefinitionName
    }
    New-AzureRmRoleAssignment -ApplicationId $app.ApplicationId -ResourceGroupName $resourceGroupName -RoleDefinitionName "Contributor"
}

# Start the deployment
Write-Host "Starting deployment...";
if(Test-Path $parametersFilePath) {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Verbose
} else {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath;
}
