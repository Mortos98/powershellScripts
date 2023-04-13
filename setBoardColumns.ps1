#take in params of OrganizationName, Project Name and PersonalAccessToken
param(
    [Parameter(Mandatory=$true)][string]$Organization,
    [Parameter(Mandatory=$true)][string]$ProjectID,
    [Parameter(Mandatory=$true)][string]$PersonalAccessToken
)
#install modules
Install-Module -Name powershell-yaml -Force

echo $PersonalAccessToken | az devops login --org $Organization
Write-Host '===Configuring connection to organization and Team Project'
az devops configure --defaults organization=$Organization project=$ProjectID

#sandpit
#$ProjectID = '822ff071-4d9e-4c88-889b-e5202458d169'
#acprojects
#$ProjectID = '210b9876-92d5-4124-9d69-32dfe38106d3'

$defaultDeliveryFeature = @(
@{
id = $IncommingId
name = "New"
itemLimit = 0
stateMappings = @{
"ART Feature" = "New"
}
columnType = "incoming"
},
@{
name = "Discovery"
itemLimit = 0
stateMappings = @{
"ART Feature" = "Discovery"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
name = "Ready for Prioritisation"
itemLimit = 0
stateMappings = @{
"ART Feature" = "Ready for Prioritisation"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
name = "Ready for Delivery"
itemLimit = 0
stateMappings = @{
"ART Feature" = "Ready for PI Planning"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
name = "Backlog"
itemLimit = 0
stateMappings = @{
"ART Feature" = "PI Backlog"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
name = "In Analysis and Design"
itemLimit = 0
stateMappings = @{
"ART Feature" = "In Analysis and Design"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
name = "Ready for Development"
itemLimit = 0
stateMappings = @{
"ART Feature" = "Ready for Development"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
name = "In Development"
itemLimit = 0
stateMappings = @{
"ART Feature" = "In Development"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
name = "Ready for test"
itemLimit = 0
stateMappings = @{
"ART Feature" = "Ready for test"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
name = "In Test"
itemLimit = 0
stateMappings = @{
"ART Feature" = "In Test"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
name = "Ready for UAT"
itemLimit = 0
stateMappings = @{
"ART Feature" = "Ready for UAT"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
name = "Final Review"
itemLimit = 0
stateMappings = @{
"ART Feature" = "PO Review"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
name = "Ready for Release"
itemLimit = 0
stateMappings = @{
"ART Feature" = "Ready for Release"
}
isSplit = $false
description = ""
columnType = "inProgress"
},
@{
id = $OutgoingId
name = "Closed"
itemLimit = 0
stateMappings = @{
"User Story" = "Closed"
}
columnType = "outgoing"
}
)

function getTeams{
    param(
        [Parameter(ValueFromRemainingArguments=$true)][String[]]$targetSettings
    )
    #list all teams
    $targetSettings | Format-Table | Out-String|% {Write-Host $_}
    $teams = az devops team list --org $Organization --project $ProjectID | ConvertFrom-Json -Depth 10 | Select Name,ID
    $teamTable = @{}
    #check teams in provided yml
    foreach($setting in $targetSettings){
        Write-Host $setting.name
        foreach($team in $teams){
            if($team.name -contains $targetSettings.name){
                $key = $team.name
                $value = $team.id
                $teamTable.add($key, $value)
                $msg = "Team Found $team.name" 
                Write-Host "Team Found" 
            }
        }
    }
    if($teamTable.count -eq 0){
        Write-Host 'No team name matches the supplied teams exiting application...'
        EXIT
    }
    elseif($teamTable.count -ne $targetSettings.count){
        Write-Host 'One or more supplied team names can not be found exiting application...'
        Exit
    }

    Write-Host 'Teams that are applying column changes'    
    $teamTable.Name | Format-List | Out-String|% {Write-Host $_}

    return $teamTable

}

function getIncommingId {

}

function getOutgoingId {

}

function getTeamConfiguration {
    $targetSettings = @()
    Resolve-Path "Board Column Updates"
    [string[]]$fileContent = Get-Content "Board Column Updates/INPUT.yml" -Raw 
    $yaml = $fileContent | ConvertFrom-Yaml | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10
    $yaml.GetEnumerator() | ForEach-Object{
        $targetSettings += $yaml
    }

    return $targetSettings
}

$targetSettings = getTeamConfiguration 
#$TargetTeamNames = @('Example Team 1 Dev', 'Example Team 2 Dev')
$teams = getTeams -targetSettings $targetSettings
foreach($key in $teams.keys) {
    $teamId = $teams[$key]
    #set backlog type Delivery|Requirements|Custom
    #for each board level
    #get incoming id
    #get outgoing id
    #run command with
    $boardName = ''
    $columns = $defaultDeliveryFeature
}
