 $context = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -match "demoporveniraccount"}).Context

 #Obtener VHDS
 Get-AzureStorageBlob  -Blob "spVMOSDisk.vhd" -Container vhds -Context $context
 #Eliminar VHDS
 Remove-AzureStorageBlob  -Blob "spVMOSDisk.vhd" -Container vhds -Context $context