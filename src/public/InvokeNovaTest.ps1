function Invoke-NovaTest {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string[]]$TagFilter,
        [string[]]$ExcludeTagFilter,
        [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
        [string]$OutputVerbosity,
        [ValidateSet('Auto', 'Ansi')]
        [string]$OutputRenderMode
    )

    end {
        $workflowContext = Get-NovaTestWorkflowContext -TestOption @{
            TestMode = 'Unit'
            TagFilter = $TagFilter
            ExcludeTagFilter = $ExcludeTagFilter
            OutputVerbosity = $OutputVerbosity
            OutputRenderMode = $OutputRenderMode
        } -BoundParameters $PSBoundParameters

        $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)
        if (-not $shouldRun -and -not $WhatIfPreference) {
            return
        }

        Invoke-NovaTestWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun
    }
}
