$vmssObject = Get-AzureRmVmss -ResourceGroupName $greenrg -VMScaleSetName $vmssName
$vmssObject.virtualMachineProfile.storageProfile.osDisk.image.uri= $newImageURI
$instances = Get-AzureRmVmssVM -VMScaleSetName $vmssName -ResourceGroupName $greenrg
foreach($instance in $instances){
    Update-AzureRmVmssInstance -ResourceGroupName $greenrg -VMScaleSetName $vmssName -InstanceId $instance.InstanceID
}