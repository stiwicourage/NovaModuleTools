function Invoke-NovaRelease {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [hashtable]$PublishOption = @{},
        [switch]$SkipTests,
        [string]$Path = (Get-Location).Path
    )

    Push-Location -LiteralPath $Path
    try {
        $releasePublishOption = @{}
        foreach ($optionName in $PublishOption.Keys) {
            $releasePublishOption[$optionName] = $PublishOption[$optionName]
        }

        $releasePublishOption.SkipTests = [bool]$SkipTests
        $workflowContext = Get-NovaPublishWorkflowContext -ProjectInfo (Get-NovaProjectInfo) -PublishOption $releasePublishOption -WorkflowParams (Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:$WhatIfPreference) -WorkflowSettings @{
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
