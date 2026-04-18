function Write-NovaLocalWorkflowMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$WorkflowName,
        [switch]$LocalRequested
    )

    if (-not $LocalRequested) {
        return
    }

    Write-Verbose "Using local $WorkflowName mode."
}
