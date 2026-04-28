function Initialize-NovaModule {
    [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
    param (
        [string]$Path = (Get-Location).Path,
        [switch]$Example
    )

    $workflowContext = Get-NovaModuleInitializationWorkflowContext -Path $Path -Example:$Example

    if (-not $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Action)) {
        return
    }

    Invoke-NovaModuleInitializationWorkflow -WorkflowContext $workflowContext
}
