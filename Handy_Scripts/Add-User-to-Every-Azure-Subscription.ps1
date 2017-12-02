Login-AzureRmAccount -Credential $Credential
Connect-MsolService -Credential $Credential 

$subs = Get-AzureRmSubscription

foreach($sub in $subs)
{
    $subID = $sub.SubscriptionId

    Write-Output("`nSubscription Name: " + $sub.SubscriptionName + "`n")

    Select-AzureRmSubscription -SubscriptionId $subID

    $substring = "/subscriptions/" + $subID

    New-AzureRmRoleAssignment -SignInName esmaeil@example.com -RoleDefinitionName owner -Scope $substring

    Write-Output("`User is added `n")
}