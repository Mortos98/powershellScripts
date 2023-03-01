#invoke a rest get request for the api create a get request to call https://dev.azure.com/TGAAU/_apis/projects/Aged Care Projects/teams?api-version=7.0
#this will return a list of teams in the project

$cred = Get-Credential
$uri = "https://dev.azure.com/TGAAU/_apis/projects/Aged Care Projects/teams?api-version=7.0"
$uri = [System.Uri]::EscapeUriString($uri)
$uri = [System.Uri]::new($uri)
$uri = $uri.AbsoluteUri
$uri = [System.Uri]::new($uri)

$body = @{
    "uri" = $uri
    "method" = "GET"
    "headers" = @{
        "Content-Type" = "application/json"
    }
    "body" = ""
}

#list returned teams
$teams = Invoke-RestMethod @body -Credential $cred
$teams.value | select customDisplayName
