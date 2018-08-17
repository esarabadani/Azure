#Deploys a Virtual Machine Scale Set (with OS managed disk from an image) with an internal load balancer in front of it
#refer to this blog post for more information: https://wp.me/p9qR9L-5e 

$Credential = Get-Credential

Add-AzureRmAccount -Credential $Credential

Select-AzureRmSubscription -SubscriptionId "Put your subscription ID here"

#This is your resource group in which your image, and all your other resources are located
$prodrg = "green-rg" 
$loc = "North Europe"
$vnetname = "greenvnet"
$LBFrontendNewPrivateIPAddress = "10.0.0.5" #This is the frontend IP address of the load balancer and should be changed with every new deployment and should be in the same range as the main subnet
$vmssName = 'vmssgreen'; #This has to be a unique name and needs to be changed with every new deployment
$imageuri = "/subscriptions/subscriptionID/resourceGroups/green-rg/providers/Microsoft.Compute/images/vm-image01" #This has to be a new image URI with every new deployment

#Specify VMSS Specific Details
$adminUsername = 'esmaeil';
$adminPassword = "putyourpasswordhere";

$PublisherName = 'Canonical'
$Offer         = 'UbuntuServer'
$Sku          = '16.04-LTS'
$Version       = 'latest'
$vmNamePrefix = 'ubuvmss'

#Specify Number of Nodes in the VMSS
$numberofnodes = 3

$SubnetName = "subnet1"

#Creates a new subnet and vNet
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix "10.0.0.0/24"

$vnet = New-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $prodrg -Location $loc -AddressPrefix "10.0.0.0/16" -Subnet $subnet

#Creates and configures an internal load balancer
$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name LB-Frontend -PrivateIpAddress $LBFrontendNewPrivateIPAddress -SubnetId $vnet.subnets[0].Id

$beaddresspool= New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "LB-backend"

$inboundNATRule1= New-AzureRmLoadBalancerInboundNatRuleConfig -Name "SSH" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 22 -BackendPort 22

$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name "HealthProbe" -RequestPath "index.html" -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2

$lbrule = New-AzureRmLoadBalancerRuleConfig -Name "HTTP" -FrontendIpConfiguration $frontendIP -BackendAddressPool $beAddressPool -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80

$nrplb = New-AzureRmLoadBalancer -ResourceGroupName $prodrg -Name "NRP-LB" -Location $loc -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule1 -LoadBalancingRule $lbrule -BackendAddressPool $beAddressPool -Probe $healthProbe

$backendnic1= New-AzureRmNetworkInterface -ResourceGroupName $prodrg -Name lb-nic1-be -Location $loc -Subnet $subnet -LoadBalancerBackendAddressPool $nrplb.BackendAddressPools[0] -LoadBalancerInboundNatRule $nrplb.InboundNatRules[0]

#Creates a vm scale set

$ILB = Get-AzureRmLoadBalancer -Name "NRP-LB" -ResourceGroupName $prodrg

$subnetId = (Get-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet).Id

$vmssipconf_ILB_BEAddPools = $ILB.BackendAddressPools[0].Id

$ipCfg = New-AzureRmVmssIPConfig -Name 'nic' -LoadBalancerBackendAddressPoolsId $vmssipconf_ILB_BEAddPools -SubnetId $subnetId;

$vmss = New-AzureRmVmssConfig -Location $loc -SkuCapacity $numberofnodes -SkuName 'Standard_DS3' -UpgradePolicyMode 'automatic' `
| Add-AzureRmVmssNetworkInterfaceConfiguration -Name $SubnetName -Primary $true -IPConfiguration $ipCfg `
| Set-AzureRmVmssOSProfile -ComputerNamePrefix $vmNamePrefix -AdminUsername $adminUsername -AdminPassword $adminPassword `
| Set-AzureRmVmssStorageProfile -OsDiskCreateOption FromImage -ManagedDisk Premium_LRS  -OsDiskCaching ReadWrite -OsDiskOsType Linux -ImageReferenceId $imageuri

New-AzureRmVmss -ResourceGroupName $prodrg -Name $vmssName -VirtualMachineScaleSet $vmss -Verbose;
