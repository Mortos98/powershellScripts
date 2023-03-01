#take in params of OrganizationName, Project Name and PersonalAccessToken
param(
    [Parameter(Mandatory=$true)]
    [string]$OrganizationName,
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    [Parameter(Mandatory=$true)]
    [string]$PersonalAccessToken
)

# create a get request for https://dev.azure.com/TGAAU/_apis/projects/Aged Care Projects/teams?api-version=7.0 with PAT Token
$uri = "https://dev.azure.com/$OrganizationName/_apis/projects/$ProjectName/teams?api-version=7.0"
# escape the uri string
$uri = [System.Uri]::EscapeUriString($uri)
# encrypt a blank string and the  PersonalAccessToken with base 64
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":$PersonalAccessToken")))

#invoke the rest call
$teams = Invoke-RestMethod -Uri $uri -Methon Get -ContentType "application/json; charset=utf-8; api-version=7.0" -Headers @{"Authorization"="Basic $encodedCredentials"}

Write-Output $teams