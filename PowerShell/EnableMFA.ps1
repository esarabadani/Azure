#This script will enable Multi-Factor Autentication for all your Azure Users... This script also requires users to use MFA when using Office365

Connect-MsolService
Login-AzureRmAccount

$subs = Get-AzureRmSubscription

$st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$st.RelyingParty = "*"
$st.State = “Disabled”
$sta = @($st)

foreach($sub in $subs)
{
    $subID = $sub.SubscriptionId
    Write-Host("`nSubscription Name: " + $sub.SubscriptionName + "`n")
    Select-AzureRmSubscription -SubscriptionId $subID
    $substring = "/subscriptions/" + $subID
    $usersList = (Get-AzureRmRoleAssignment -IncludeClassicAdministrators -scope $substring)

    foreach($user in $usersList){
        if($user.ObjectType -eq "User")
        {
            Set-MsolUser -UserPrincipalName $user.SignInName -StrongAuthenticationRequirements $sta
        }
    }
}

