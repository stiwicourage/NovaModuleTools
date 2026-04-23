function Test-NovaBuild {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string[]]$TagFilter,
        [string[]]$ExcludeTagFilter,
        [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
        [string]$OutputVerbosity,
        [ValidateSet('Auto', 'Ansi')]
        [string]$OutputRenderMode
    )
    $workflowContext = Get-NovaTestWorkflowContext -TestOption @{
        TagFilter = $TagFilter
        ExcludeTagFilter = $ExcludeTagFilter
        OutputVerbosity = $OutputVerbosity
        OutputRenderMode = $OutputRenderMode
    } -BoundParameters $PSBoundParameters

    if (-not $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)) {
        return
    }

    Invoke-NovaTestWorkflow -WorkflowContext $workflowContext
}
