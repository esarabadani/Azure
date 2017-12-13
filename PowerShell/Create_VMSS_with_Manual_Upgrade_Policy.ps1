Add-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId "Put your Azure Subscription ID here"

$greenrg = "bluegreen" #Enter the name of your resource group here
$loc = "West Europe" #Enter the region of your choice here
$vnetname = "bgvnet" #Enter the virtual network name here
$backendSubnetName = "subnet1" #This is the name of your subnet in the virtual network
$LBFrontendNewPrivateIPAddress = "10.1.0.6" #This is the frontend IP Address of your internal load balancer. Make sure it is in the same range as your subnet
$stName = "bgvmss" #This is the storage account name (for the scale set)
$vmssName = 'esmaeilbgvmss'; #This has to be a unique name and needs to be changed with every redeployment
$imageuri = "https://container_name_here.blob.core.windows.net/images/image01.vhd" #This is the URI of your base image 
$newImageURI = "https://container_name_here.blob.core.windows.net/images/image02.vhd" #This is the URI of your new base image which will be reflected on the scale set
$instanceId = "1" #This is the ID of the vm instance in the vm scale set
$numberofnodes = 3 #This is the number of instances in your scale set


#Specify VMSS Specific Details
$adminUsername = 'esmaeil';
$adminPassword = "Put your password here";

$PublisherName = 'MicrosoftWindowsServer'
$Offer         = 'WindowsServer'
$Sku          = '2012-R2-Datacenter'
$Version       = 'latest'
$vmNamePrefix = 'winvmss'

#Add an Extension
$extname = 'BGInfo';
$publisher = 'Microsoft.Compute';
$exttype = 'BGInfo';
$extver = '2.1';

New-AzureRmResourceGroup -Name $greenrg -Location $loc -Force;
$backendSubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -AddressPrefix "10.1.0.0/24"
$vnet = New-AzureRmVirtualNetwork -ResourceName $vnetname -Location $loc -ResourceGroupName $greenrg -Subnet $backendSubnetConfig -AddressPrefix "10.1.0.0/24"
$subnetMain = Get-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -VirtualNetwork $vnet
$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name LB-Frontend -PrivateIpAddress $LBFrontendNewPrivateIPAddress -SubnetId $subnetMain.Id
$beaddresspool= New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "LB-backend"
$inboundNATRule1= New-AzureRmLoadBalancerInboundNatRuleConfig -Name "RDP" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3389 -BackendPort 3389
$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name "HealthProbe" -RequestPath "index.html" -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
$lbrule = New-AzureRmLoadBalancerRuleConfig -Name "HTTP" -FrontendIpConfiguration $frontendIP -BackendAddressPool $beAddressPool -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80
$nrplb = New-AzureRmLoadBalancer -ResourceGroupName $greenrg -Name "NRP-LB" -Location $loc -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule1 -LoadBalancingRule $lbrule -BackendAddressPool $beAddressPool -Probe $healthProbe
$backendSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -VirtualNetwork $vnet
$backendnic1= New-AzureRmNetworkInterface -ResourceGroupName $greenrg -Name lb-nic1-be -Location $loc -Subnet $backendSubnet -LoadBalancerBackendAddressPool $nrplb.BackendAddressPools[0] -LoadBalancerInboundNatRule $nrplb.InboundNatRules[0]
$ILB = Get-AzureRmLoadBalancer -Name "NRP-LB" -ResourceGroupName $greenrg
$backendSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -VirtualNetwork $vnet
$subnetId = (Get-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -VirtualNetwork $vnet).Id
$vmssipconf_ILB_BEAddPools = $ILB.BackendAddressPools[0].Id
$ipCfg = New-AzureRmVmssIPConfig -Name 'nic' -LoadBalancerBackendAddressPoolsId $vmssipconf_ILB_BEAddPools -SubnetId $subnetId;
$vmss = New-AzureRmVmssConfig -Location $loc -SkuCapacity $numberofnodes -SkuName 'Standard_DS3' -UpgradePolicyMode 'Manual' `
| Add-AzureRmVmssNetworkInterfaceConfiguration -Name $backendSubnet -Primary $true -IPConfiguration $ipCfg `
| Set-AzureRmVmssOSProfile -ComputerNamePrefix $vmNamePrefix -AdminUsername $adminUsername -AdminPassword $adminPassword `
| Set-AzureRmVmssStorageProfile -Name "test" -OsDiskCreateOption 'FromImage' -OsDiskCaching ReadWrite -OsDiskOsType Windows -Image $imageuri `
| Add-AzureRmVmssExtension -Name $extname -Publisher $publisher -Type $exttype -TypeHandlerVersion $extver -AutoUpgradeMinorVersion $true
New-AzureRmVmss -ResourceGroupName $greenrg -Name $vmssName -VirtualMachineScaleSet $vmss -Verbose;