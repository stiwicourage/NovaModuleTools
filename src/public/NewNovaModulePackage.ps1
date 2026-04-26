function New-NovaModulePackage {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$SkipTests
    )

    $workflowContext = Get-NovaPackageWorkflowContext -WorkflowParams (Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:$WhatIfPreference) -SkipTestsRequested:$SkipTests
    $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)

    return Invoke-NovaPackageWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun
}
