#take in params of OrganizationName, Project Name and PersonalAccessToken
param(
    [Parameter(Mandatory=$true)][string]$Organization,
    [Parameter(Mandatory=$true)][string]$ProjectID,
    [Parameter(Mandatory=$true)][string]$PersonalAccessToken
)

#install modules
Install-Module -Name powershell-yaml -Force

echo $PersonalAccessToken | az devops login --org $Organization
Write-Host '##[section]Configuring connection to organization and Team Project'
az devops configure --defaults organization=$Organization project=$ProjectID


#sandpit
#$ProjectID = '822ff071-4d9e-4c88-889b-e5202458d169'
#acprojects
#$ProjectID = '210b9876-92d5-4124-9d69-32dfe38106d3'


function Read-TeamConfiguration {
    [string[]]$fileContent = Get-Content "Rolling Iteration Updates/INPUT.yml" -Raw 
    $yaml = $fileContent | ConvertFrom-Yaml | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10
    $yaml

    return [pscustomobject]$targetSettings
}

function Get-TeamSettingArray {
    param(
        [Parameter(Mandatory=$true)]$settings
    )
    $teams = @()
    foreach($team in $settings){
        $new = [PSCustomObject]@{
            name = $team.name
            type = $team.type
            forecast = $team.forecast
        }
        $teams += $new
    }
    return $teams
}

function Get-Teams{
    param(
        [Parameter(Mandatory=$true)]$teams
    )
    Write-Host "##[command]Searching for teams"
    $teamsToChange = @()
    $json = az devops team list --org $Organization --project $ProjectID | ConvertFrom-Json
    foreach($team in $json) {
        if($teams.name.Contains($team.name)){
            $settings = $teams | Where-Object{$_.name -eq $team.name}
            $new = [PSCustomObject]@{
                id = $team.id
                name = $team.name
                type = $settings.type
                forecast = $settings.forecast
            }
            Write-Host "Found" $team.name -ForegroundColor red 
            $teamsToChange += $new
        }
    }
    Write-Host "##[section]Done, updating the following teams iterations.."
    return $teamsToChange
}

function Get-SprintList{
    param(
    [Parameter(Mandatory=$true)][System.Object]$iterations
    )
    $sprints = @()
    foreach($PI in $iterations){
        foreach($sprint in $PI.children){
            $sprints += $sprint
        }
    }

    return $sprints
}

function Get-PIList{
    param(
        [Parameter(Mandatory=$true)][System.Object]$iterations
    )
    $PIs = $iterations.children
    return $PIs
}

function Get-IterationsList{
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
    $PIObject = $top.children | Where-Object{($_.name -eq 'Aged Care PIs')}
    return $PIObject
}

function Get-LastIteration{
    param(
        [Parameter(Mandatory=$true)]$iterations
    )

    if($PIs.name -contains $iterations[-1].name){
        $lastIteration = $PIs | Where-Object { $_.name -eq $iterations[-1].name}
    }
    if($sprints.name -contains $iterations[-1].name){
        $lastIteration = $sprints | Where-Object { $_.name -eq $iterations[-1].name}
    }

    $lastIteration = az boards iteration project show --id $lastIteration.id --org $Organization --project $ProjectID | ConvertFrom-Json

    return $lastIteration
}

function Get-CurrentIterationTimeFrame{
    param(
        [Parameter(Mandatory=$true)][System.Object]$team
    )

    $currentSprint = az boards iteration team list --team $team --org $Organization --project $ProjectID --timeframe current | ConvertFrom-Json
    return $currentSprint
}

function Set-ForcastSprints{
    param(
        [Parameter(Mandatory=$true)][System.Object]$team,
        [Parameter(Mandatory=$true)][System.Object]$iterations
    )

    foreach($iteration in $iterations){
        az boards iteration team add --team $team.id --id $iteration.id --org $Organization --project $ProjectID
    }

}

function Get-LastIterationIndex{
    param(
        [Parameter(Mandatory=$true)][System.Object]$iterations,
        [Parameter(Mandatory=$true)][System.Object]$lastSprint
    )

    [int]$index = 0

    foreach($iteration in $iterations){
        if($iteration.name -eq  $lastSprint.name){
            return [int]$index
        }

        $index ++
    }
}

function Get-TeamIterations{
    param(
        [Parameter(Mandatory=$true)][System.Object]$team
    )   

    $teamIterationList = az boards iteration team list --team $team.id --org $Organization --project $ProjectID | ConvertFrom-Json
    return $teamIterationList
}

function Print-OpeningSettings{
    param(
        [Parameter(Mandatory=$true)][System.Object]$settings,
        [Parameter(Mandatory=$true)][System.Object]$PIs,
        [Parameter(Mandatory=$true)][System.Object]$sprints,
        [Parameter(Mandatory=$true)][System.Object]$teamsToChange
    ) 

    Write-Host "##[section]"Input Submitted
    $settings | Format-Table -AutoSize 
    Write-Host "##[section]"PIs Found
    $PIs | Format-Table -AutoSize -Property name, @{Name='Start Date'; Expression={$_.attributes.startDate}},@{Name='End Date'; Expression={$_.attributes.finishDate}}
    Write-Host "##[section]"Sprints Found
    $sprints | Format-Table -AutoSize -Property name, @{Name='Start Date'; Expression={$_.attributes.startDate}},@{Name='End Date'; Expression={$_.attributes.finishDate}}
    Write-Host "##[section]"Teams Found
    $teamsToChange | Format-Table -AutoSize

}

function Print-CurrentTeamSettings{
    param(
        [Parameter(Mandatory=$true)][System.Object]$teamIterationList,
        [Parameter(Mandatory=$true)][System.Object]$lastIteration,
        [Parameter(Mandatory=$true)][System.Object]$currentTimeframe,
        [Parameter(Mandatory=$true)][System.Object]$team
    ) 
    Write-Host "##[command]Team"  $team.name
    Write-Host "##[section]Team Iteration List"
    $teamIterationList | Format-Table -AutoSize -Property name, @{Name='Start Date'; Expression={$_.attributes.startDate}},@{Name='End Date'; Expression={$_.attributes.finishDate}}
    Write-Host "##[section]Team Last Iteration"
    $lastIteration | Format-Table -AutoSize -Property name, @{Name='Start Date'; Expression={$_.attributes.startDate}},@{Name='End Date'; Expression={$_.attributes.finishDate}}
    Write-Host "##[section]Team Current Iteration"
    $currentTimeframe | Format-Table -Property name, @{Name='Start Date'; Expression={$_.attributes.startDate}},@{Name='End Date'; Expression={$_.attributes.finishDate}}
}

$settings = Read-TeamConfiguration
$iterationList = Get-IterationsList
$PIs = Get-PIList -iterations $iterationList
$sprints = Get-SprintList -iterations $PIs
$teamArray = Get-TeamSettingArray -settings $settings
$teamsToChange = Get-Teams -teams $teamArray

Print-OpeningSettings -settings $settings -PIs $PIs -sprints $sprints -teamsToChange $teamsToChange

#get PI List
Write-Host '##[section]===Get Team Iteration List'
foreach($team in $teamsToChange){
    $teamIterationList = Get-TeamIterations -team $team
    $lastIteration = Get-LastIteration -iterations $teamIterationList
    $currentTimeframe = Get-CurrentIterationTimeFrame -team $team.id
    $today = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'AUS Eastern Standard Time')

    if($team.type -eq "PI"){
        $selectedIterations = $PIs
    }
    else{
        $selectedIterations = $sprints
    }

    $index = Get-LastIterationIndex -iterations $selectedIterations -lastSprint $lastIteration
    Write-Host $index

    Print-CurrentTeamSettings -teamIterationList $teamIterationList -lastIteration $lastIteration -currentTimeFrame $currentTimeframe -team $team
    IF($today -gt $lastIteration.attributes.finishDate){
        Write-Host "actions -Filter designated list to > today"
        $selectedIterations = $selectedIterations.where({[datetime]$_.attributes.startDate -gt $today})
        $selectedIterations
        Write-Host "actions -iterations = get forecast -forecast 6"
        Write-Host "actions -set forecast -iterations -team"
    }
    else{
        Write-Host "actions -iterations = get forecast -forecast 6"
        Write-Host "actions -set forecast -iterations -team"
    }
}
