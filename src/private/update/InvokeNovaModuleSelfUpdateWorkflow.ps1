function Invoke-NovaModuleSelfUpdateOrStop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Plan
    )

    try {
        $null = Invoke-NovaModuleSelfUpdate -ModuleName $Plan.ModuleName -AllowPrerelease:$Plan.UsedAllowPrerelease
    }
    catch {
        Stop-NovaOperation -Message $_.Exception.Message -ErrorId 'Nova.Dependency.ModuleSelfUpdateFailed' -Category InvalidOperation -TargetObject $Plan.ModuleName
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
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $plan = $WorkflowContext.Plan
    if (-not $plan.UpdateAvailable) {
        return Complete-NovaModuleSelfUpdateResult -Plan $plan -ReleaseNotesUri $null
    }

    Invoke-NovaModuleSelfUpdateOrStop -Plan $plan
    $plan.Updated = $true
    $releaseNotesUri = Get-NovaModuleReleaseNotesUri
    return Complete-NovaModuleSelfUpdateResult -Plan $plan -ReleaseNotesUri $releaseNotesUri
}
