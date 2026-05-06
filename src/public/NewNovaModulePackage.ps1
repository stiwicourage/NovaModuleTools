function New-NovaModulePackage {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$SkipTests,
        [switch]$OverrideWarning
    )

    $workflowContext = Get-NovaPackageWorkflowContext -WorkflowParams (Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:$WhatIfPreference) -SkipTestsRequested:$SkipTests -OverrideWarningRequested:$OverrideWarning
    $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)

    return Invoke-NovaPackageWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun
}
