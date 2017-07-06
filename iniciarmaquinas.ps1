clear-host

 try{
    Get-AzureRmSubscription -SubscriptionName $subscrName | Select-AzureRmSubscription
 }
 catch{
    Login-AzureRMAccount
 
 }

$rgName="DemoIntranetPorvenir"
write-host "Iniciando adVM" -ForegroundColor Cyan
Start-AzureRMVM -Name adVM -ResourceGroupName $rgName
write-host "Iniciando sqlVM" -ForegroundColor Cyan
Start-AzureRMVM -Name sqlVM -ResourceGroupName $rgName
write-host "Iniciando spVM" -ForegroundColor Cyan
Start-AzureRMVM -Name spVM -ResourceGroupName $rgName
#Start-AzureRMVM -Name spVMWFE1 -ResourceGroupName $rgName
