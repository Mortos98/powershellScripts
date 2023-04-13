#take in params of OrganizationName, Project Name and PersonalAccessToken
param(
    [Parameter(Mandatory=$true)][string]$Organization,
    [Parameter(Mandatory=$true)][string]$ProjectID,
    [Parameter(Mandatory=$true)][string]$PersonalAccessToken
)

echo $PersonalAccessToken | az devops login --org $Organization
Write-Host '===Configuring connection to organization and Team Project'
az devops configure --defaults organization=$Organization project=$ProjectID


#sandpit
#$ProjectID = '822ff071-4d9e-4c88-889b-e5202458d169'
#acprojects
#$ProjectID = '210b9876-92d5-4124-9d69-32dfe38106d3'

function getIterationsList{
    Write-Host '===Get Iterations All'
    $json = az boards iteration project list --depth 4 --org $Organization --project $ProjectID
    $jsonObj = $json | ConvertFrom-Json
    $top = [PSCustomObject] @{
        name = $jsonObj.name
        path = $jsonObj.path
        hasChildren = $jsonObj.hasChildren
        id = $jsonObj.id
        children = $jsonObj.children
        startDate = $null
        endDate = $null
    } 
    $iterationList = @()
    $iterationList = buildIterationList -iterations $top.children
    return $iterationList
}

function buildIterationList{
    param(
    [Parameter(Mandatory=$true)][System.Object]$iterations,
    [Parameter(Mandatory=$false)][System.Object]$output
    )
    foreach($iteration in $iterations){
        $new = [PSCustomObject] @{
            name = $iteration.name
            path = $iteration.path
            hasChildren = $iteration.hasChildren
            id = $iteration.id
            children = $iteration.children
            startDate = $iteration.attributes.startDate
            endDate = $iteration.attributes.finishDate
        } 
        if($new.path.Contains('\Aged Care Sandpit\Iteration\Aged Care PIs\') -and  $new.name.Length -ne 5){
            $output + $new
            echo $output
        }
        if([bool]($new.PSobject.Properties.name -match "hasChildren")){
            if($new.hasChildren -eq "True"){
                $output += buildIterationList -iterations $new.children -output $output
            }
        }
    }
    return $output
}

function getTeams{
    Write-Host '===get Teams List'
    $teamList = @()
    $json = az devops team list --org $Organization --project $ProjectID | ConvertFrom-Json
    foreach($team in $json) {
        if($teamsToUpdate.Contains($team.name)){
            Write-Host $team.name
            $new = [PSCustomObject]@{
                name = $team.name
                id = $team.id
            }
            $teamList += $new
        }
    }
    return $teamList
}

function getTeamIterations{
    Write-Host '===Get Team Iteration List'
    $teamsLatestIterationList = @()
    $teamsIterationList = @()
    #$teamList | Format-Table | Out-String|% {Write-Host $_}
    foreach($team in $teamList){
        $teamIterationList = az boards iteration team list --team $team.id --org $Organization --project $ProjectID | ConvertFrom-Json
        foreach($iteration in $teamIterationList){
            if ($iteration.attributes.timeFrame -eq "current"){
                $teamsLatestIteration = [PSCustomObject]@{
                    name = $team.name
                    id = $team.id
                    iterationStart = $iteration.attributes.startDate
                    iterationEnd = $iteration.attributes.endDate
                    iterationName = $iteration.name
                    iterationPath = $iteration.path
                    iterationId = $iteration.id
                }
                $teamsLatestIterationList + $teamsLatestIteration
            }
            $new = [PSCustomObject]@{
                    name = $team.name
                    id = $team.id
                    iterationStart = $iteration.attributes.startDate
                    iterationEnd = $iteration.attributes.endDate
                    iterationName = $iteration.name
                    iterationPath = $iteration.path
                    iterationId = $iteration.id
                }
            $teamsIterationList + $new
        }
    }
    $output = @($teamsLatestIterationList, $teamsIterationList)
    $output | Format-Table | Out-String|% {Write-Host $_}
    return $output

}

function getForcast{
    #gets next 6 iterations
}

$iterationList = @()
$teamList =@()
$teamsToUpdate = @('Example team 1','Example Team 1 Dev','Example team 2','Example Team 2 Dev') #this will need to be updated to some form of yml list and integrated to a board column update
$teamIterationLatestList =@() 
$teamIterations =@()
#$iterationList = getIterationsList
$teamList = getTeams
$TeamIterations = getTeamIterations
$teamIterationLatestList = $teamIterations.teamIterationLatestList
$teamIterationList = $teamIterations.teamIterationList

#Write-Host '===Print Iterations'
#$global:iterationList | Format-Table | Out-String|% {Write-Host $_}
Write-Host '===Print Teams'
$global:teamList | Format-Table | Out-String|% {Write-Host $_}
Write-Host '===Print Teams Latest Iteration'
$global:teamsLatestIterationList | Format-Table | Out-String|% {Write-Host $_}
Write-Host '===Print Teams Iterations'
$global:teamsIterationList | Format-Table | Out-String|% {Write-Host $_}