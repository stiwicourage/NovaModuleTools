function Invoke-NovaBuildValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $overrideWarningRequested = ($WorkflowContext.PSObject.Properties.Name -contains 'OverrideWarningRequested') -and $WorkflowContext.OverrideWarningRequested
    $workflowParams = Get-NovaBuildCommandParameterMap -WorkflowParams $WorkflowContext.WorkflowParams -OverrideWarningRequested:$overrideWarningRequested
    $skipTestsRequested = ($WorkflowContext.PSObject.Properties.Name -contains 'SkipTestsRequested') -and $WorkflowContext.SkipTestsRequested
    Invoke-NovaBuild @workflowParams
    if (-not $skipTestsRequested) {
        Invoke-NovaTest @workflowParams
        Test-NovaBuild @workflowParams
        return
    }

    Write-Verbose 'Skipping Invoke-NovaTest and Test-NovaBuild because SkipTests was requested for this workflow.'
}
