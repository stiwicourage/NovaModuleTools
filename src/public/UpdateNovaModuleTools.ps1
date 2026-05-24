function Update-NovaModuleTool {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('Update-NovaModuleTools')]
    param()

    $workflowContext = Get-NovaModuleSelfUpdateWorkflowContext -WorkflowParams @{WhatIf = [bool]$WhatIfPreference}
    $plan = $workflowContext.Plan
    if ($plan.IsPrereleaseTarget -and -not $WhatIfPreference) {
        $prereleaseConfirmed = Confirm-NovaPrereleaseModuleUpdate -Cmdlet $PSCmdlet -CurrentVersion $plan.CurrentVersion -TargetVersion $plan.TargetVersion
        if (-not $prereleaseConfirmed) {
            $plan.Cancelled = $true
            return Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext $workflowContext -ShouldRun:$false
        }
    }

    $shouldRun = $plan.UpdateAvailable -and $PSCmdlet.ShouldProcess($plan.ModuleName, $workflowContext.Action)
    if (-not $shouldRun) {
        $plan.Cancelled = (-not $WhatIfPreference) -and $plan.UpdateAvailable
    }

    $result = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun
    Write-NovaModuleReleaseNotesLink -ReleaseNotesUri $result.ReleaseNotesUri
    return $result
}
