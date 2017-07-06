 try{
    Get-AzureRmSubscription -SubscriptionName $subscrName | Select-AzureRmSubscription
 }
 catch{
    Login-AzureRMAccount
 }
 $rgName="DemoIntranetPorvenir"
Stop-AzureRMVM -Name spVM -ResourceGroupName $rgName -Force
Stop-AzureRMVM -Name sqlVM -ResourceGroupName $rgName -Force
Stop-AzureRMVM -Name adVM -ResourceGroupName $rgName -Force
Stop-AzureRMVM -Name spVMWFE1 -ResourceGroupName $rgName -Force