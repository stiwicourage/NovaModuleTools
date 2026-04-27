function Update-NovaModuleTool {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('Update-NovaModuleTools')]
    param()

    $workflowContext = Get-NovaModuleSelfUpdateWorkflowContext
    $plan = $workflowContext.Plan
    if (-not $plan.UpdateAvailable) {
        return Complete-NovaModuleSelfUpdateResult -Plan $plan -ReleaseNotesUri $null
    }

    if ($plan.IsPrereleaseTarget -and -not (Confirm-NovaPrereleaseModuleUpdate -Cmdlet $PSCmdlet -CurrentVersion $plan.CurrentVersion -TargetVersion $plan.TargetVersion)) {
        $plan.Cancelled = $true
        return Complete-NovaModuleSelfUpdateResult -Plan $plan -ReleaseNotesUri $null
    }

    if (-not $PSCmdlet.ShouldProcess($plan.ModuleName, $workflowContext.Action)) {
        return Complete-NovaModuleSelfUpdateResult -Plan $plan -ReleaseNotesUri $null
    }

    $result = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext $workflowContext
    Write-NovaModuleReleaseNotesLink -ReleaseNotesUri $result.ReleaseNotesUri
    return $result
}
