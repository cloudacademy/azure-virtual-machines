# azure-virtual-machines
### Demo - Build a Windows Virtual machine in the new portal
```Get-NetIPConfiguration```


### Demo - Build a Linux Virtual machine in the new portal
```ifconfig```

```ping 10.0.0.4```

```Test-Connection 10.0.0.5```


### Azure VM Pricing Tiers
https://azure.microsoft.com/en-us/pricing/

https://azure.microsoft.com/en-us/pricing/calculator/?service=virtual-machines


### Starting and Stopping Azure VMs
```Stop-Computer```

### Demo - Deploy an Azure PowerShell DSC Configuration
```
Configuration DSC_IIS
{
      Node "localhost"
      {
            WindowsFeature IIS
            {
                  Ensure = "Present"
                  Name = "Web-Server"
            }
      }
}
```

```Get-WindowsFeature | Where DisplayName -Like *IIS*```

```
# Login
Add-AzureRmAccount # -EnvironmentName
```

```
#region Variable Definitions
$resourceGroupName = "ExtensionRG"
$targetVM  = "ExtensionVM"
$storageAccountName = "dscscripts" # pre-provisioned
$DSCcontainer = "powershellscripts" # must be lowercase letters
#endregion

#region Publish configuration and extension

# help Publish-AzureRmVMDscConfiguration -ShowWindow

#Publish configuration to storage account (creates <configFileName.ps1.zip> file)
Publish-AzureRmVMDscConfiguration -ResourceGroupName $resourceGroupName
-StorageAccountName $storageAccountName
-ContainerName $DSCcontainer
-ConfigurationPath ".\DSC_IIS.ps1"
-Force


# help Set-AzureRmVMDscExtension -ShowWindow

#Deploy the PowerShell DSC extension and invoke our configuration on the target Node
Set-AzureRmVmDscExtension -Version "2.24"
-ResourceGroupName $resourceGroupName
-VMName $targetVM
-ArchiveStorageAccountName $storageAccountName
-ArchiveContainerName $DSCcontainer
-ArchiveBlobName DSC_IIS.ps1.zip
-ConfigurationName "DSC_IIS"
-Force

#endregion

#region Get PowerShell DSC Extension Version
# Get the Extension
Get-AzureRmVmImagePublisher -Location EastUS | Where-Object PublisherName -eq Microsoft.Powershell |
Get-AzureRmVMExtensionImageType |
Get-AzureRmVMExtensionImage |
Select PublisherName,Type,Version | Sort-Object Version -Descending
#endregion
```

### Desired State Configuration Wrap-Up

Ben Lambert - Getting started with Chef
https://cloudacademy.com/cloud-computing/getting-started-chef-course

Trevor Sullivan - Microsoft Azure Automation
https://cloudacademy.com/azure/automation-course

### Overview and Demo of VM Extensions
```
$PhysicalDisk = Get-PhysicalDisk | Where-Object CanPool -eq $true
New-StoragePool -FriendlyName "StoragePool1" -StorageSubsystemFriendlyName "Storage Spaces*" -PhysicalDisks $PhysicalDisk
$virtualDisk = New-VirtualDisk -StoragePoolFriendlyName "StoragePool1" -UseMaximumSize -ProvisioningType Fixed -ResiliencySettingName "Simple" - FriendlyName "DataDisk"
$virtualDisk | Initialize-Disk -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -Force -Confirm:$false
```

```
# List VM extensions
Get-Command -Module AzureRM.Compute -Verb Set -Noun *Extension

#region Setup variables
$resourceGroupName = "ExtensionRG"
$vmName = "ExtensionVM"
$extensionName = "InitializeDiskScript"
$location = "EastUS"
$storageAccountName = "dscscripts"
$containerName = "powershellscripts"
$scriptName = "InitializeDataDisk.ps1"
#endregion

Set-AzureRmVMCustomScriptExtension -ResourceGroupName $resourceGroupName
-VMName $vmName
-Location $location
-StorageAccountName $storageAccountName
-ContainerName $containerName
-FileName $scriptName
-Name $extensionName
-Run "InitializeDataDisk.ps1"
```

### Overview of Azure VM Storage Capacities

Azure subscription and service limits, quotas, and constraints
https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits/

### Demo - Implement BitLocker Disk Encryption on an Azure VM

```
# This PowerShell script creates a new Resource Group where it deploys a new Windows VM, a Keyvault with an AD App and 
# KeyEncryptionKey which is used to encrypt the VM.
# Please log in to your Azure Environment before running this script. This script creates all new resources.
# For more info: https://docs.microsoft.com/en-us/security/azure-security-disk-encryption

$ResourceGroupName = "EncryptRG"
$VMName = "EncryptWin1"
$Location = "East US"
$Subnet1Name = "default"
$VNetName = "Encrypt-VNet"
$InterfaceName = $VMName + "-NIC"
$PublicIPName = $VMName + "-PIP"
$ComputerName = $VMName
$VMSize = "Standard_DS3_v2"
$username = "admin123"
$password = "Password123!@#"
$StorageName = "storage" + $VMName.ToLower()
$StorageType = "Standard_LRS"
$OSDiskName = $VMName + "OSDisk"
$OSPublisherName = "MicrosoftWindowsServer"
$OSOffer = "WindowsServer"
$OSSKu = "2012-R2-Datacenter"
$OSVersion = "latest"


# Create The Resource Group
Write-Host "Creating ResourceGroup: $ResourceGroupName..."
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

#region KeyVault
############################## Create and Deploy the KeyVault and Keys ###############################
$keyVaultName = MyKeyVault1Commercial"
$aadAppName = "MyApp1"
$aadClientID = ""
$aadClientSecret = ""
$keyEncryptionKeyName = "MyKey1"

# Create a new AD application
Write-Host "Creating a new AD Application: $aadAppName..."
$identifierUri = [string]::Format("http://localhost:8080/{0}",[Guid]::NewGuid().ToString("N"))
$defaultHomePage = 'http://contoso.com'
$now = [System.DateTime]::Now
$oneYearFromNow = $now.AddYears(1)
$aadClientSecret = [Guid]::NewGuid()
$ADApp = New-AzureRmADApplication -DisplayName $aadAppName -HomePage $defaultHomePage -IdentifierUris $identifierUri -StartDate $now -EndDate $oneYearFromNow -Password $aadClientSecret
$servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $ADApp.ApplicationId
$aadClientID = $servicePrincipal.ApplicationId
Write-Host "Successfully create a new AAD Application: $aadAppName with ID: $aadClientID"

# Create the KeyVault
Write-Host "Creating the KeyVault: $keyVaultName..."
$keyVault = New-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $ResourceGroupName -Sku Standard -Location $Location;
# Set the permissions to 'all' and Enable the DiskEncryption Policy
Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVaultName -ServicePrincipalName $aadClientID -PermissionsToKeys all -PermissionsToSecrets all
Set-AzureRmKeyVaultAccessPolicy - VaultName $keyVaultName -EnabledForDiskEncryption
$diskEncryptionKeyVaultUrl = $keyVault.VaultUri
$keyVaultResourceId = $keyVault.ResourceId

# Create the KeyEncryptionKey (KEK)
Write-Host "Creating the KeyEncryptionKey (KEK): $keyEncryptionKeyName..."
$kek = Add-AzureKeyVaultKey -VaultName $keyVaultName -Name $keyEncryptionKeyName -Destination Software
$keyEncryptionKeyUrl - $kek.Key.Kid

# Output the values of the KeyVault
Write-Host "KeyVault Vales that will be needed to enable encryption on the VM" -foregroundcolor Cyan
Write-Host "KeyVault Name: $keyVaultName" -foregroundcolor Cyan
Write-Host "aadClientID: $aadClientID" -foregroundcolor Cyan
Write-Host "aadClientSecret: $aadClientSecret - foregroundcolor Cyan
Write-Host "diskEncryptionKeyVaultUrl: $diskEncryptionKeyVaultUrl" -foregroundcolor Cyan
Write-Host "keyVaultResourceId: $keyVaultResourceId" - foregroundcolor Cyan
Write-Host "keyEncryptionKeyURL: $keyEncryptionKeyUrl" - foregroundcolor Cyan
#endregion

#region VM
############################## Create and Deploy the VM ###############################
# Create storage account
Write-Host "Creating storage account: $StorageName..."
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -SkuName $StorageType -Location $Location

# Create a Public IP
Write-Host "Creating a Public IP: $PublicIPName..."
$publicIP = New-AzureRmPublicIpAddress -Name $PublicIPName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic

# Create the VNet
Write-Host "Creating a VNet: $VNetName..."
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name "default" -AddressPrefix "192.168.1.0/24"
$VNet = New-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName -AddressPrefix "192.168.0.0/16" -Location $Location -Subnet $subnetConfig
$myNIC = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $publicip.Id

# Create the VM Credentials
Write-Host "Creating VM Credentials..."
$secureStringPwd = $password | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $secureStringPwd

# Create the basic VM config
Write-Host "Creating the basic VM config..."
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -ComputerName $VMName -Windows -Credential $Credential
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $myNIC.Id

# Create OS Disk Uri and attach it to the VM
Write-Host "Creating the OSDisk '$OSDiskName' for the VM..."
$NewOSDiskVhdUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + 'vhds/" + $vmName.ToLower() + "-" + $osDiskName + '.vhd'
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName $OSPublisherName -offer $OSOffer -Skus $OSSKu -Version $OSVersion
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $osDiskName -VhdUri $NewOSDiskVhdUri -CreateOption FromImage

# Create the VM
Write-Host "Building the VM: $VMName..."
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine
#endregion

#region Encryption Extension
############################## Deploy the VM Encryption Extension ###############################
# Build the encryption extension
Write-Host "Deploying the VM Encryption Extension..."
Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $resourceGroupName -VMName $vmName
-AadClientID $aadClientID -AadClientSecret $aadClientSecret
-DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId
-VolumeType "OS"
-KeyEncryptionKeyUrl $keyEncryptionKeyUrl
-KeyEncryptionKeyVaultId $keyVaultResourceId
-Force

Get-AzureRmVMDiskEncryptionStatus -ResourceGroupName $ResourceGroupName -VMName $VNMame
#endregion
```












