function Update-NovaModuleVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$Path = (Get-Location).Path,
        [switch]$Preview,
        [switch]$ContinuousIntegration
    )

    $projectRoot = (Resolve-Path -LiteralPath $Path).Path
    if ($ContinuousIntegration -and -not $WhatIfPreference) {
        $null = Import-NovaBuiltModuleForCi -ProjectRoot $projectRoot
    }

    $workflowContext = Get-NovaVersionUpdateWorkflowContext -ProjectRoot $projectRoot -PreviewRelease:$Preview -ContinuousIntegrationRequested:$ContinuousIntegration


    $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Action)

    return Invoke-NovaVersionUpdateWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun -WhatIfEnabled:$WhatIfPreference
}
