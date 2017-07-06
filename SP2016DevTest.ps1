
function crearVM(){
    
    write-host "Creando Maquina Virtual AD" -ForegroundColor Green
        try{
   

            # Get the location and storage account names
            $locName=(Get-AzureRmResourceGroup -Name $rgName).Location
            $saName=(Get-AzureRMStorageaccount | Where {$_.ResourceGroupName -eq $rgName}).StorageAccountName

            # Create an availability set for domain controller virtual machines
            New-AzureRMAvailabilitySet -Name dcAvailabilitySet -ResourceGroupName $rgName -Location $locName

            # Create the domain controller virtual machine
            $vnet=Get-AzureRMVirtualNetwork -Name SP2016Vnet -ResourceGroupName $rgName
            $pip = New-AzureRMPublicIpAddress -Name adVM-PIP -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic
            $nic = New-AzureRMNetworkInterface -Name adVM-NIC -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress 10.0.0.4

            $avSet=Get-AzureRMAvailabilitySet -Name dcAvailabilitySet -ResourceGroupName $rgName 
            $vm=New-AzureRMVMConfig -VMName adVM -VMSize Standard_D1_v2 -AvailabilitySetId $avSet.Id

            $storageAcc=Get-AzureRMStorageAccount -ResourceGroupName $rgName -Name $saName
            $vhdURI=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/adVM-SP2016Vnet-ADDSDisk.vhd"
            Add-AzureRMVMDataDisk -VM $vm -Name ADDS-Data -DiskSizeInGB 20 -VhdUri $vhdURI  -CreateOption empty
            $cred=Get-Credential -Message "Type the name and password of the local administrator account for adVM."

            $vm=Set-AzureRMVMOperatingSystem -VM $vm -Windows -ComputerName adVM -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
            $vm=Set-AzureRMVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
            $vm=Add-AzureRMVMNetworkInterface -VM $vm -Id $nic.Id
            $osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/adVM-SP2016Vnet-OSDisk.vhd"
            $vm=Set-AzureRMVMOSDisk -VM $vm -Name adVM-SP2016Vnet-OSDisk -VhdUri $osDiskUri -CreateOption fromImage
            New-AzureRMVM -ResourceGroupName $rgName -Location $locName -VM $vm
        }
        catch{
           Write-host $_.Exception.Message
            return
        }
}

function crearCuentaAlmacenamiento(){
    
        ##########################################################
        write-host "Creando Cuenta de Almacenamiento"

        $saName="demoporveniraccount"
        $locName=(Get-AzureRmResourceGroup -Name $rgName).Location
        New-AzureRMStorageAccount -Name $saName -ResourceGroupName $rgName -Type Standard_LRS -Location $locName
        ###############################################################

        write-host "Creando Red Virtual" -ForegroundColor Yellow

        try{

            $locName=(Get-AzureRmResourceGroup -Name $rgName).Location
            $spSubnet=New-AzureRMVirtualNetworkSubnetConfig -Name SP2016Subnet -AddressPrefix 10.0.0.0/24
            New-AzureRMVirtualNetwork -Name SP2016Vnet -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $spSubnet -DNSServer 10.0.0.4
            $rule1=New-AzureRMNetworkSecurityRuleConfig -Name "RDPTraffic" -Description "Allow RDP to all VMs on the subnet" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
            $rule2 = New-AzureRMNetworkSecurityRuleConfig -Name "WebTraffic" -Description "Allow HTTP to the SharePoint server" -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix "10.0.0.6/32" -DestinationPortRange 80
            New-AzureRMNetworkSecurityGroup -Name SP2016Subnet -ResourceGroupName $rgName -Location $locName -SecurityRules $rule1, $rule2
            $vnet=Get-AzureRMVirtualNetwork -ResourceGroupName $rgName -Name SP2016Vnet
            $nsg=Get-AzureRMNetworkSecurityGroup -Name SP2016Subnet -ResourceGroupName $rgName
            Set-AzureRMVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name SP2016Subnet -AddressPrefix "10.0.0.0/24" -NetworkSecurityGroup $nsg
            
        }
        catch
        {
            Write-host $_.Exception.Message
            return
        }
}

function crearGrupoRecursos()
{
       
        #Get-AzureRmSubscription -SubscriptionName $subscr | Select-AzureRmSubscription


        write-host "Creando Grupo de Recursos" -ForegroundColor Green
        try{
        $rgName="DemoIntranetPorvenir"
        $locName="southcentralus"
        New-AzureRMResourceGroup -Name $rgName -Location $locName
        
        }
        catch{

            Write-host $_.Exception.Message
            return
        }


}

function crearVMDataBase()
{
    $vmName="sqlVM"
    $vmSize="Standard_D3_V2"
    write-host "Creando Vm Base de Datos $vmName $vmSize" -ForegroundColor Yellow
    try{
            # Create an availability set for SQL Server virtual machines
            New-AzureRMAvailabilitySet -Name sqlAvailabilitySet -ResourceGroupName $rgName -Location $locName

            # Create the SQL Server virtual machine
           
            $vnet=Get-AzureRMVirtualNetwork -Name "SP2016Vnet" -ResourceGroupName $rgName

            $nicName=$vmName + "-NIC"
            $pipName=$vmName + "-PIP"
            $pip=New-AzureRMPublicIpAddress -Name $pipName -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic
            $nic=New-AzureRMNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress "10.0.0.5"
            $avSet=Get-AzureRMAvailabilitySet -Name sqlAvailabilitySet -ResourceGroupName $rgName 
            $vm=New-AzureRMVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avSet.Id

            $diskSize=100
            $diskLabel="SQLData"
            $storageAcc=Get-AzureRMStorageAccount -ResourceGroupName $rgName -Name $saName
            $vhdURI=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + "-SQLDataDisk.vhd"
            Add-AzureRMVMDataDisk -VM $vm -Name $diskLabel -DiskSizeInGB $diskSize -VhdUri $vhdURI  -CreateOption empty

            $cred=Get-Credential -Message "Type the name and password of the local administrator account of the SQL Server computer." 
            $vm=Set-AzureRMVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
            #Se define el tipo de maquina o plantilla a usar
            $vm=Set-AzureRMVMSourceImage -VM $vm -PublisherName MicrosoftSQLServer -Offer SQL2016-WS2016 -Skus Standard -Version "latest"
            $vm=Add-AzureRMVMNetworkInterface -VM $vm -Id $nic.Id
            $storageAcc=Get-AzureRMStorageAccount -ResourceGroupName $rgName -Name $saName
            $osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + "-OSDisk.vhd"
            $vm=Set-AzureRMVMOSDisk -VM $vm -Name "OSDisk" -VhdUri $osDiskUri -CreateOption fromImage
            New-AzureRMVM -ResourceGroupName $rgName -Location $locName -VM $vm
    }
    catch{
           Write-host $_.Exception.Message
           return
    }
}

function crerSPVM(){
        write-host "Creando Maquina de SharePoint" -foregroundcolor yellow
        # Set up key variables
       try{
                # Set up key variables
           
            $dnsName="porvenirintranet"

            # Set the Azure subscription
            Get-AzureRmSubscription -SubscriptionName $subscrName | Select-AzureRmSubscription

            # Get the location and Azure storage account names
            $locName=(Get-AzureRmResourceGroup -Name $rgName).Location
            $saName=(Get-AzureRMStorageaccount | Where {$_.ResourceGroupName -eq $rgName}).StorageAccountName

            # Create an availability set for SharePoint virtual machines
            New-AzureRMAvailabilitySet -Name spAvailabilitySet -ResourceGroupName $rgName -Location $locName

            # Specify the virtual machine name and size
            $vmName="spVM"
            $vmSize="Standard_D3_V2"
            $vm=New-AzureRMVMConfig -VMName $vmName -VMSize $vmSize

            # Create the NIC for the virtual machine
            $nicName=$vmName + "-NIC"
            $pipName=$vmName + "-PIP"
            $pip=New-AzureRMPublicIpAddress -Name $pipName -ResourceGroupName $rgName -DomainNameLabel $dnsName -Location $locName -AllocationMethod Dynamic
            $vnet=Get-AzureRMVirtualNetwork -Name "SP2016Vnet" -ResourceGroupName $rgName
            $nic=New-AzureRMNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress "10.0.0.6"
            $avSet=Get-AzureRMAvailabilitySet -Name spAvailabilitySet -ResourceGroupName $rgName 
            $vm=New-AzureRMVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avSet.Id

            # Specify the image and local administrator account, and then add the NIC
            $pubName="MicrosoftSharePoint"
            $offerName="MicrosoftSharePointServer"
            $skuName="2016"
            $cred=Get-Credential -Message "Type the name and password of the local administrator account."
            $vm=Set-AzureRMVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
            $vm=Set-AzureRMVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
            $vm=Add-AzureRMVMNetworkInterface -VM $vm -Id $nic.Id

            # Specify the OS disk name and create the VM
            $diskName="OSDisk"
            $storageAcc=Get-AzureRMStorageAccount -ResourceGroupName $rgName -Name $saName
            $osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
            $vm=Set-AzureRMVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage
            Write-Host "Creando Maquina Virtual " -ForegroundColor DarkCyan
            New-AzureRMVM -ResourceGroupName $rgName -Location $locName -VM $vm -DisableBginfoExtension
       }
       catch{
            write-error  $_.Exception.Message
       }
       
}

   Clear-Host
   $rgName="DemoIntranetPorvenir"
   $locName="southcentralus"
   write-host "Creando Ambiente de Pruebas SharePoint 2016" -foregroundcolor green
   write-host "Ubicacion $locName"  -foregroundcolor white
   write-host "Grupo de Recursos $rgName"  -foregroundcolor green
   try{
             write-host "Obteniendo Crendenciales"   -foregroundcolor green
            Get-AzureRmSubscription -SubscriptionName $subscrName | Select-AzureRmSubscription
   }
   catch{
    Login-AzureRMAccount
    #Get-AzureRmSubscription -SubscriptionName $subscrName | Select-AzureRmSubscription
   }
 
 
 $subscr="Visual Studio Enterprise con MSDN"
 # Set the Azure subscription

$locName=(Get-AzureRmResourceGroup -Name $rgName).Location
$saName=(Get-AzureRMStorageaccount | Where {$_.ResourceGroupName -eq $rgName}).StorageAccountName


<#crearGrupoRecursos
crearCuentaAlmacenamiento#>
crearVM
crearVMDataBase


