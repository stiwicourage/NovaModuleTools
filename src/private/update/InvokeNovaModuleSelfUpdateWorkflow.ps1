function Get-NovaModuleSelfUpdateFailureMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FailureDetail
    )

    return @(
        "NovaModuleTools self-update failed: $FailureDetail"
        'Confirm that the PowerShell Gallery is reachable and that this session can update installed modules, then rerun the self-update command.'
    ) -join [Environment]::NewLine
}

function Invoke-NovaModuleSelfUpdateOrStop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Plan
    )

    try {
        $null = Invoke-NovaModuleSelfUpdate -ModuleName $Plan.ModuleName -AllowPrerelease:$Plan.UsedAllowPrerelease
    } catch {
        $message = Get-NovaModuleSelfUpdateFailureMessage -FailureDetail $_.Exception.Message
        Stop-NovaOperation -Message $message -ErrorId 'Nova.Dependency.ModuleSelfUpdateFailed' -Category InvalidOperation -TargetObject $Plan.ModuleName
    }
}

function Complete-NovaModuleSelfUpdateResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Plan,
        [AllowNull()][string]$ReleaseNotesUri
    )

    if ($Plan.PSObject.Properties.Name -contains 'ReleaseNotesUri') {
        $Plan.ReleaseNotesUri = $ReleaseNotesUri
        return $Plan
    }

    $Plan | Add-Member -NotePropertyName 'ReleaseNotesUri' -NotePropertyValue $ReleaseNotesUri
    return $Plan
}

function Invoke-NovaModuleSelfUpdateWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    $progressActivity = 'Updating NovaModuleTools'
    $result = $null

    if (Test-NovaModuleSelfUpdateWorkflowShouldSkipExecution -WorkflowContext $WorkflowContext -ShouldRun:$ShouldRun) {
        $result = Complete-NovaModuleSelfUpdateResult -Plan $WorkflowContext.Plan -ReleaseNotesUri $null
        Write-NovaModuleSelfUpdateWorkflowResult -Result $result -WorkflowContext $WorkflowContext
        return $result
    }

    try {
        Invoke-NovaModuleSelfUpdateWorkflowStep -Activity $progressActivity -Status (Get-NovaModuleSelfUpdateWorkflowUpdateStatus -WorkflowContext $WorkflowContext) -PercentComplete 80 -Action {
            Invoke-NovaModuleSelfUpdateOrStop -Plan $WorkflowContext.Plan
        }

        $WorkflowContext.Plan.Updated = $true
        $releaseNotesUri = Invoke-NovaModuleSelfUpdateWorkflowStep -Activity $progressActivity -Status 'Reading release notes from the updated module' -PercentComplete 95 -Action {
            Get-NovaModuleReleaseNotesUri
        }

        $result = Complete-NovaModuleSelfUpdateResult -Plan $WorkflowContext.Plan -ReleaseNotesUri $releaseNotesUri
    } finally {
        Write-Progress -Activity $progressActivity -Completed
    }

    Write-NovaModuleSelfUpdateWorkflowResult -Result $result -WorkflowContext $WorkflowContext
    return $result
}

function Test-NovaModuleSelfUpdateWorkflowShouldSkipExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    return (-not $WorkflowContext.Plan.UpdateAvailable) -or (-not $ShouldRun)
}

function Invoke-NovaModuleSelfUpdateWorkflowStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Activity,
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][int]$PercentComplete,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    & $Action
}

function Write-NovaModuleSelfUpdateWorkflowResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result,
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $whatIfEnabled = Test-NovaModuleSelfUpdateWorkflowWhatIfEnabled -WorkflowContext $WorkflowContext
    Write-Message (Get-NovaModuleSelfUpdateWorkflowStatusMessage -Result $Result -WhatIfEnabled:$whatIfEnabled) -color (Get-NovaModuleSelfUpdateWorkflowStatusColor -Result $Result)
    Write-Message "Current version: $( $Result.CurrentVersion )"

    $targetVersionLine = Get-NovaModuleSelfUpdateWorkflowTargetVersionLine -Result $Result
    if (-not [string]::IsNullOrWhiteSpace($targetVersionLine)) {
        Write-Message $targetVersionLine
    }

    $repositoryLine = Get-NovaModuleSelfUpdateWorkflowRepositoryLine -Result $Result
    if (-not [string]::IsNullOrWhiteSpace($repositoryLine)) {
        Write-Message $repositoryLine
    }

    foreach ($line in (Get-NovaModuleSelfUpdateWorkflowNextStepLine -Result $Result -WhatIfEnabled:$whatIfEnabled)) {
        Write-Message $line
    }
}

function Test-NovaModuleSelfUpdateWorkflowWhatIfEnabled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    return $WorkflowContext.WorkflowParams.ContainsKey('WhatIf') -and $WorkflowContext.WorkflowParams.WhatIf
}

function Get-NovaModuleSelfUpdateWorkflowUpdateStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    if ($WorkflowContext.Plan.IsPrereleaseTarget) {
        return "Installing prerelease version $( $WorkflowContext.Plan.TargetVersion )"
    }

    return "Installing version $( $WorkflowContext.Plan.TargetVersion )"
}

function Get-NovaModuleSelfUpdateWorkflowStatusMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result,
        [switch]$WhatIfEnabled
    )

    if (-not $Result.UpdateAvailable) {
        return 'NovaModuleTools is already up to date.'
    }

    if ($WhatIfEnabled) {
        return 'Self-update plan ready for NovaModuleTools'
    }

    if ($Result.Cancelled) {
        return 'Self-update cancelled for NovaModuleTools.'
    }

    return "Updated NovaModuleTools to version $( $Result.TargetVersion )."
}

function Get-NovaModuleSelfUpdateWorkflowStatusColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result
    )

    if ($Result.Cancelled) {
        return 'Blue'
    }

    return 'Green'
}

function Get-NovaModuleSelfUpdateWorkflowTargetVersionLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result
    )

    if (-not $Result.UpdateAvailable) {
        return $null
    }

    return "Target version: $( $Result.TargetVersion )"
}

function Get-NovaModuleSelfUpdateWorkflowRepositoryLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result
    )

    if ([string]::IsNullOrWhiteSpace($Result.LookupRepository)) {
        return $null
    }

    return "Repository: $( $Result.LookupRepository )"
}

function Get-NovaModuleSelfUpdateWorkflowNextStepLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result,
        [switch]$WhatIfEnabled
    )

    if (-not $Result.UpdateAvailable -or $Result.Cancelled) {
        return @()
    }

    if ($WhatIfEnabled) {
        return @(
            'Next step:'
            "Run Update-NovaModuleTool without -WhatIf when you are ready to install version $( $Result.TargetVersion )."
        )
    }

    return @(
        'Next step:'
        'Get-NovaProjectInfo -InstalledNovaVersion'
    )
}
