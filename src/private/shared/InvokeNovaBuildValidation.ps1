function Invoke-NovaBuildValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $workflowParams = $WorkflowContext.WorkflowParams
    $skipTestsRequested = ($WorkflowContext.PSObject.Properties.Name -contains 'SkipTestsRequested') -and $WorkflowContext.SkipTestsRequested
    Invoke-NovaBuild @workflowParams
    if (-not $skipTestsRequested) {
        Test-NovaBuild @workflowParams
        return
    }

    Write-Verbose 'Skipping Test-NovaBuild because SkipTests was requested for this workflow.'
}
