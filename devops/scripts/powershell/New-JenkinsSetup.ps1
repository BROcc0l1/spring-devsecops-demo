[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]$Location,
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]$FileShareName,
    [Parameter(Mandatory = $true)]
    [string]$KeyVaultName
)

Write-Host "Resource group: $ResourceGroupName"
Write-Host "Resource group location: $ResourceGroupLocation"
Write-Host "Storage account for persistant volume: $StorageAccountName"
Write-Host "File share: $FileShareName"
Write-Host "================================================`n"

try {
    Write-Host "Creating resource group..."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    
    Write-Host "Creating storage account..."
    New-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName -Location $Location -SkuName Standard_LRS
    
    Write-Host "Creating fileshare..."
    New-AzRmStorageShare -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -Name $FileShareName 

    Write-Host "Creating KeyVault..."
    New-AzKeyVault -Name $KeyVaultName -ResourceGroupName $ResourceGroupName -Location $Location

    Write-Host "Saving storage account key and name to KeyVault..."
    $storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value | ConvertTo-SecureString -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name "jenkins-storage-key" -SecretValue $storageAccountKey
    Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name "jenkins-storage-account-name" -SecretValue $(ConvertTo-SecureString $StorageAccountName)

    Write-Host "Setting delete lock on the created RG..."
    Set-AzResourceLock `
        -LockName "$ResourceGroupName-delete-lock" `
        -LockLevel "CanNotDelete" `
        -LockNotes "Jenkins storage and KeyVault must not be deleted to save Jenkins state while being able to destroy it with Terraform to save costs" `
        -ResourceGroupName $ResourceGroupName `
        -Force
}
catch {
    Write-Error "$($_.Exception.Message)"
}
