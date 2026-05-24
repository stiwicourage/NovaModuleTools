function Invoke-NovaVersionUpdateWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun,
        [switch]$WhatIfEnabled
    )

    $versionWriteResult = $null
    $progressActivity = 'Updating Nova module version'
    try {
        if ($ShouldRun) {
            $versionWriteResult = Invoke-NovaVersionUpdateWorkflowStep -Activity $progressActivity -Status (Get-NovaVersionUpdateApplyStatus -WorkflowContext $WorkflowContext) -PercentComplete 80 -Action {
                Set-NovaModuleVersion -ProjectInfo $WorkflowContext.ProjectInfo -Label (Get-NovaVersionUpdateEffectiveLabel -WorkflowContext $WorkflowContext) -PreviewRelease:$WorkflowContext.PreviewRelease -Confirm:$false
            }
        }
    }
    finally {
        if ($ShouldRun) {
            Write-Progress -Activity $progressActivity -Completed
        }
    }

    $wasApplied = $null -ne $versionWriteResult -and $versionWriteResult.Applied
    $wasCancelled = (-not $ShouldRun) -and (-not $WhatIfEnabled)
    return Get-NovaVersionUpdateResult -WorkflowContext $WorkflowContext -Applied:$wasApplied -Previewed:$WhatIfEnabled -Cancelled:$wasCancelled
}

function Invoke-NovaVersionUpdateWorkflowStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Activity,
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][int]$PercentComplete,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    return & $Action
}

function Get-NovaVersionUpdateApplyStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $target = Get-NovaVersionUpdateTarget -WorkflowContext $WorkflowContext
    return "Writing version $( $WorkflowContext.NewVersion ) to $target"
}

function Get-NovaVersionUpdateEffectiveLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $effectiveLabel = Get-NovaVersionUpdateWorkflowPropertyValue -WorkflowContext $WorkflowContext -Name 'EffectiveLabel'
    if (-not [string]::IsNullOrWhiteSpace($effectiveLabel)) {
        return $effectiveLabel
    }

    return Get-NovaVersionUpdateWorkflowPropertyValue -WorkflowContext $WorkflowContext -Name 'Label'
}

function Get-NovaVersionUpdateResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$Applied,
        [switch]$Previewed,
        [switch]$Cancelled
    )

    return [pscustomobject]@{
        PreviousVersion = Get-NovaVersionUpdateWorkflowPropertyValue -WorkflowContext $WorkflowContext -Name 'PreviousVersion'
        NewVersion = Get-NovaVersionUpdateWorkflowPropertyValue -WorkflowContext $WorkflowContext -Name 'NewVersion'
        Label = Get-NovaVersionUpdateWorkflowPropertyValue -WorkflowContext $WorkflowContext -Name 'Label'
        EffectiveLabel = Get-NovaVersionUpdateEffectiveLabel -WorkflowContext $WorkflowContext
        AdvisoryMessage = Get-NovaVersionUpdateAdvisoryMessage -WorkflowContext $WorkflowContext
        CommitCount = Get-NovaVersionUpdateWorkflowPropertyValue -WorkflowContext $WorkflowContext -Name 'CommitCount'
        ProjectFile = Get-NovaVersionUpdateProjectFile -WorkflowContext $WorkflowContext
        Target = Get-NovaVersionUpdateTarget -WorkflowContext $WorkflowContext
        Applied = [bool]$Applied
        Previewed = [bool]$Previewed
        Cancelled = [bool]$Cancelled
    }
}

function Get-NovaVersionUpdateAdvisoryMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    return Get-NovaVersionUpdateWorkflowPropertyValue -WorkflowContext $WorkflowContext -Name 'AdvisoryMessage'
}

function Get-NovaVersionUpdateProjectFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $projectInfo = Get-NovaVersionUpdateWorkflowPropertyValue -WorkflowContext $WorkflowContext -Name 'ProjectInfo'
    if ($null -eq $projectInfo) {
        return $null
    }

    $projectFileProperty = $projectInfo.PSObject.Properties['ProjectJSON']
    if ($null -eq $projectFileProperty) {
        return $null
    }

    return $projectFileProperty.Value
}

function Get-NovaVersionUpdateTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $projectFile = Get-NovaVersionUpdateProjectFile -WorkflowContext $WorkflowContext
    if (-not [string]::IsNullOrWhiteSpace($projectFile)) {
        return [System.IO.Path]::GetFileName($projectFile)
    }

    return Get-NovaVersionUpdateWorkflowPropertyValue -WorkflowContext $WorkflowContext -Name 'Target'
}

function Get-NovaVersionUpdateWorkflowPropertyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [Parameter(Mandatory)][string]$Name
    )

    $property = $WorkflowContext.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}
