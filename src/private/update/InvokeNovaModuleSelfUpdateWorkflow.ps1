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

function Invoke-NovaModuleSelfUpdateWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $plan = $WorkflowContext.Plan
    if (-not $plan.UpdateAvailable) {
        return $plan
    }

    Invoke-NovaModuleSelfUpdateOrStop -Plan $plan
    $plan.Updated = $true
    Write-NovaModuleReleaseNotesLink
    return $plan
}
