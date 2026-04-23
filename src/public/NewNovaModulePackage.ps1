function New-NovaModulePackage {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $workflowContext = Get-NovaPackageWorkflowContext -WorkflowParams (Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:$WhatIfPreference)
    $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)

    return Invoke-NovaPackageWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun
}
