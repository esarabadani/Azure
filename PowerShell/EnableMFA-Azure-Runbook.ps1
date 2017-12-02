#The code below adds users who are members of Azure subscriptions to a specific group. You can then enable Multi-Factor Authentication for the members of this group

$azureCredential = Get-AutomationPSCredential -Name "AzMonkey"

if($azureCredential -ne $null)
{
	Write-Output "Attempting to authenticate as: [$($azureCredential.UserName)]"
}
else
{
   throw "No automation credential name was specified..."
}

Connect-MsolService -Credential $azureCredential
Login-AzureRmAccount -Credential $azureCredential 
Connect-AzureAD -Credential $azureCredential

$subs = Get-AzureRmSubscription
$groupID = "Here you will need to enter the Object ID of the Azure AD group"

foreach($sub in $subs)
{
    $subID = $sub.SubscriptionId
    Select-AzureRmSubscription -SubscriptionId $subID
    $substring = "/subscriptions/" + $subID
    $usersList = (Get-AzureRmRoleAssignment -IncludeClassicAdministrators -scope $substring)

    foreach($user in $usersList){
       if(($user.ObjectType -eq "User") -and ($user.ObjectId -ne "00000000-0000-0000-0000-000000000000"))
       {
            $userGroups = Get-AzureADUserMembership -ObjectId $user.ObjectID
       }
       if(($user.ObjectType -eq "User") -and ($user.SignInName -ne "azmonkey@example.com") -and ($userGroups.ObjectID -notcontains $groupID) -and ($user.ObjectID -ne "00000000-0000-0000-0000-000000000000"))
        {
            $userID = $user.objectID
            Add-AzureADGroupMember -ObjectId $groupID -RefObjectId $userID
       }
    }
}
