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

    $result = Invoke-NovaCliInstallWorkflow -WorkflowContext $workflowContext
    Write-NovaModuleReleaseNotesLink -ReleaseNotesUri $result.ReleaseNotesUri
    return $result
}
