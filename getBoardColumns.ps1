#take in params of OrganizationName, Project Name and PersonalAccessToken
param(
    [Parameter(Mandatory=$true)]
    [string]$OrganizationName,
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    [Parameter(Mandatory=$true)]
    [string]$PersonalAccessToken
)
# encrypt a blank string and the  PersonalAccessToken with base 64
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":$PersonalAccessToken")))

# create a get request for https://dev.azure.com/TGAAU/_apis/projects/Aged Care Projects/teams?api-version=7.0 with PAT Token
$uri = "https://dev.azure.com/$OrganizationName/_apis/projects/$ProjectName/teams?api-version=7.0"
$uri = [System.Uri]::EscapeUriString($uri)

#invoke the rest call
$teams = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json; charset=utf-8; api-version=7.0" -Headers @{"Authorization"="Basic $encodedCredentials"}
# loop through teams and get team ids and names and create an object with the team name and id
foreach ($team in $teams.value) {
    $teamId = $team.id
    $teamName = $team.name

    $uriboards = "https://dev.azure.com/$OrganizationName/$projectName/$teamId/_apis/work/backlogs?api-version=7.0"
    $uriboards = [System.Uri]::EscapeUriString($uriboards)
    $boards = Invoke-RestMethod -Uri $uriboards -Method Get -ContentType "application/json; charset=utf-8; api-version=7.0" -Headers @{"Authorization"="Basic $encodedCredentials"}

    foreach ($board in $boards.value) {
        $boardId = $board.id
        $boardName = $board.name
        $boardObject = New-Object -TypeName PSObject -Property @{
            BoardName = $boardName
            BoardId = $boardId
        }
        $boardObject | Select-Object BoardName, BoardId
    }

    $teamObject = New-Object -TypeName PSObject -Property @{
        TeamName = $teamName
        TeamId = $teamId
        Boards = $boardObject
    }
    $teamObject | Select-Object TeamName, TeamId
}
