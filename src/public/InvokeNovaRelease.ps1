function Invoke-NovaRelease {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [hashtable]$PublishOption = @{},
        [string]$Path = (Get-Location).Path
    )

    Push-Location -LiteralPath $Path
    try {
        $workflowContext = Get-NovaPublishWorkflowContext -ProjectInfo (Get-NovaProjectInfo) -PublishOption $PublishOption -WorkflowParams (Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:$WhatIfPreference) -WorkflowSettings @{
            WorkflowName = 'release'
            Release = $true
        }

        Write-NovaPublishWorkflowContext -WorkflowContext $workflowContext

        $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)
        if (-not $shouldRun -and -not $WhatIfPreference) {
            return
        }

        return Invoke-NovaReleaseWorkflow -WorkflowContext $workflowContext
    }
    finally {
        Pop-Location
    }
}
