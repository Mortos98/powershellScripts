#invoke a rest get request for the api create a get request to call https://dev.azure.com/TGAAU/_apis/projects/Aged Care Projects/teams?api-version=7.0
#this will return a list of teams in the project\

$PAT = "xxxxxxxxxxxxxxxxxxxx"
$uri = "https://dev.azure.com/TGAAU/_apis/projects/Aged Care Projects/teams?api-version=7.0"
$uri = [System.Uri]::EscapeUriString($uri)
$uri = [System.Uri]::new($uri)
$uri = $uri.AbsoluteUri
$uri = [System.Uri]::new($uri)

# take a PAT and encrypt it base 64 with UTF8
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(":$PAT"))
$cred = New-Object System.Net.NetworkCredential("", $base64AuthInfo)

#creaete a get request to the uri with the cred object
@body = @{
    method = "GET"
    uri = $uri
    ContentType = "application/json"
    UseDefaultCredentials = $false
    Credential = $cred
}

#invode the get re quest and return the value of the teams
$teams = Invoke-RestMethod @body -Credential $cred
$teams.vlalue | select customDisplayName

