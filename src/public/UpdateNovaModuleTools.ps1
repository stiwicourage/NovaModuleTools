function Update-NovaModuleTool {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('Update-NovaModuleTools')]
    param()

    $workflowContext = Get-NovaModuleSelfUpdateWorkflowContext
    $plan = $workflowContext.Plan
    if (-not $plan.UpdateAvailable) {
        return $plan
    }

    if ($plan.IsPrereleaseTarget -and -not (Confirm-NovaPrereleaseModuleUpdate -Cmdlet $PSCmdlet -CurrentVersion $plan.CurrentVersion -TargetVersion $plan.TargetVersion)) {
        $plan.Cancelled = $true
        return $plan
    }

    if (-not $PSCmdlet.ShouldProcess($plan.ModuleName, $workflowContext.Action)) {
        return $plan
    }

    return Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext $workflowContext
}
