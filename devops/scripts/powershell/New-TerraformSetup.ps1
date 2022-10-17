[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]$Location,
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]$ContainerName
)

Write-Host "Resource group: $ResourceGroupName"
Write-Host "Resource group location: $ResourceGroupLocation"
Write-Host "Terrafrom storage account: $StorageaccountName"
Write-Host "Terraform conrainer: $ContainerName"
Write-Host "================================================`n"

try {
    # Create resource group for terraform storage if not exists
    Write-Host "Creating Resource Group..."

    # Check whether the RG already exists
    Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable rgNotPresent -ErrorAction SilentlyContinue
    if ($rgNotPresent) {
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    }
    else {
        Write-Warning -Message "Resource group '$ResourceGroupName' already exists, skipping creation"
    }

    # Create storage account
    Write-Host "Creating Storage Account..."

    $storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -SkuName Standard_LRS -Location $Location -AllowBlobPublicAccess $true
    #Write-Host $storageAccount

    # Create blob container
    Write-Host "Creating Blob Container..."
    New-AzStorageContainer -Name $ContainerName -Context $storageAccount.context -Permission blob

    Write-Host "Setting delete lock on the created RG..."
    Set-AzResourceLock `
        -LockName "$ResourceGroupName-delete-lock" `
        -LockLevel "CanNotDelete" `
        -LockNotes "Terraform state must not be deleted" `
        -ResourceGroupName $ResourceGroupName `
        -Force
}
catch {
    Write-Error "$($_.Exception.Message)"
}



# $accountKey=(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].value
# $env:ARM_ACCESS_KEY=$accountKey
#export ARM_ACCESS_KEY=$(az keyvault secret show --name terraform-backend-key --vault-name myKeyVault --query value -o tsv)

# Write-Information "Creating default terraform configuration..."

# $terraformBackendConfig = @"
# terraform {
#     required_providers {
#       azurerm = {
#         source  = "hashicorp/azurerm"
#         version = "=2.46.0"
#       }
#     }
#       backend "azurerm" {
#           resource_group_name  = "$ResourceGroupName"
#           storage_account_name = "$StorageAccountName"
#           container_name       = "$ContainerName"
#           key                  = "terraform.tfstate"
#       }
  
#   }
  
#   provider "azurerm" {
#     features {}
#   }
# "@

# if (Test-Path "../../infra/terraform/main.tf")
# {
#   Write-Warning "Seems like basic Terraform configuration already exists, please verify it manually."
# }
# else
# {
#    New-Item -Path "../../infra/terraform/" -Name "main.tf" -Type "file" -Value $terraformBackendConfig
#    Write-Information "Basic Terraform configuration created at devops/infra/terraform/main.tf"
# }
