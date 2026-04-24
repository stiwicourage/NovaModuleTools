function Install-NovaCli {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$DestinationDirectory,
        [switch]$Force
    )

    $workflowContext = Get-NovaCliInstallWorkflowContext -DestinationDirectory $DestinationDirectory -Force:$Force

    if (-not $PSCmdlet.ShouldProcess($workflowContext.TargetPath, $workflowContext.Action)) {
        return
    }

    return Invoke-NovaCliInstallWorkflow -WorkflowContext $workflowContext
}
