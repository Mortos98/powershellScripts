#invoke a rest get request for the api create a get request to call https://dev.azure.com/TGAAU/_apis/projects/Aged Care Projects/teams?api-version=7.0
#this will return a list of teams in the project

$PAT = "xxxxxxxxxxxxxxxxxxxx"
$uri = "https://dev.azure.com/TGAAU/_apis/projects/Aged Care Projects/teams?api-version=7.0"
$uri = [System.Uri]::EscapeUriString($uri)
$uri = [System.Uri]::new($uri)
$uri = $uri.AbsoluteUri
$uri = [System.Uri]::new($uri)

$cred = New-Object System.Management.Automation.PSCredential("PAT", (ConvertTo-SecureString $PAT -AsPlainText -Force))
$body = @{
    Method = 'Get'
    Uri = $uri
    ContentType = 'application/json'
    UseDefaultCredentials = $false
    Credential = $cred
}
#list returned teams
$teams = Invoke-RestMethod @body -Credential $cred
$teams.value | select customDisplayName
