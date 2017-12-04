Login-AzureRmAccount

$subs = Get-AzureRmSubscription

foreach($sub in $subs)
{
    $subID = $sub.SubscriptionId
    Write-Output("`nSubscription Name: " + $sub.SubscriptionName + "`n")
    $substring = "/subscriptions/" + $subID
    Get-AzureRmRoleAssignment -IncludeClassicAdministrators -scope $substring | FL SignInName 
}
