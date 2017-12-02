
#Login to Azure
Add-AzureRmAccount
 
#Select Azure Subscription
$subscription = 
    (Get-AzureRmSubscription |
        Out-GridView `
        -Title 'Select an Azure Subscription ...' `
    -PassThru)
 
Set-AzureRmContext -SubscriptionId $subscription.subscriptionId -TenantId $subscription.TenantID

#create Service Principal with Password
New-AzureRmADApplication -DisplayName "dockerscaler01" -HomePage "https://www.example.com/dockerscaler01" -IdentifierUris "https://www.example.com/dockerscaler01" -Password "P@ssw0rd12345" -OutVariable app
New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $app.ApplicationId.Guid

Get-AzureRmADApplication -DisplayNameStartWith 'dockerscaler01' -OutVariable app
Get-AzureRmADServicePrincipal -ServicePrincipalName $app.ApplicationId.Guid -OutVariable SPN

#Azure Authtentication Token

#requires -Version 3
#SPN ClientId and Secret
$ClientID       = "Enter the Client ID of the Service Principal here" #ApplicationID
$ClientSecret   = "Enter the Client Secret of the Service Principal here"  #key from Application
$tennantid      = "Enter your Azure AD tentnat ID here. You can get it from the portal."
 

$TokenEndpoint = {https://login.windows.net/{0}/oauth2/token} -f $tennantid 
$ARMResource = "https://management.core.windows.net/";

$Body = @{
        'resource'= $ARMResource
        'client_id' = $ClientID
        'grant_type' = 'client_credentials'
        'client_secret' = $ClientSecret
}

$params = @{
    ContentType = 'application/x-www-form-urlencoded'
    Headers = @{'accept'='application/json'}
    Body = $Body
    Method = 'Post'
    URI = $TokenEndpoint
}

$token = Invoke-RestMethod @params

$token | select access_token, @{L='Expires';E={[timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.expires_on))}} | fl *


$SubscriptionId = 'Enter your Azure Subscription ID here'
$ResourceGroupName = 'Enter the Resource Group name which contains the Docker Swarm Cluster'
$ContainerServiceName = 'Enter the name of your Container Service in the above Resource Group'

$ContainerURI = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ContainerService/containerServices/$ContainerServiceName" +'?api-version=2016-09-30'

$ourstring = '{
  "properties": {
    "agentPoolProfiles": [
      {
        "name": "Agentpools",
        "count": 3,
        "vmSize": "Standard_DS1",
        "dnsPrefix": "esmaeilacsmgmt"
      }
    ]
    }
}'

$finalstring = ConvertFrom-Json $ourstring

$params = @{
    ContentType = 'application/x-www-form-urlencoded'
    Headers = @{
    'authorization'="Bearer $($Token.access_token)"
    }
    Body = $finalstring
    Method = 'PUT'
    URI = $ContainerURI
}


Invoke-RestMethod @params