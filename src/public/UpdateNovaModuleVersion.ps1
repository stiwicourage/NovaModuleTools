function Update-NovaModuleVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$Path = (Get-Location).Path,
        [switch]$Preview
    )

    $projectRoot = (Resolve-Path -LiteralPath $Path).Path
    $workflowContext = Get-NovaVersionUpdateWorkflowContext -ProjectRoot $projectRoot -PreviewRelease:$Preview


    $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Action)

    return Invoke-NovaVersionUpdateWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun -WhatIfEnabled:$WhatIfPreference
}
