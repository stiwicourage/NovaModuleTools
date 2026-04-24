function Invoke-NovaModuleSelfUpdateWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $plan = $WorkflowContext.Plan
    if (-not $plan.UpdateAvailable) {
        return $plan
    }

    $null = Invoke-NovaModuleSelfUpdate -ModuleName $plan.ModuleName -AllowPrerelease:$plan.UsedAllowPrerelease
    $plan.Updated = $true
    Write-NovaModuleReleaseNotesLink
    return $plan
}
