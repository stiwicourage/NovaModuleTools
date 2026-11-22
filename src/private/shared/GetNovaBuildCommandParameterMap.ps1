function Get-NovaBuildCommandParameterMap {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [hashtable]$WorkflowParams = @{},
        [switch]$OverrideWarningRequested
    )

    $commandParams = @{}
    foreach ($parameterName in $WorkflowParams.Keys) {
        $commandParams[$parameterName] = $WorkflowParams[$parameterName]
    }

    if ($OverrideWarningRequested) {
        $commandParams.OverrideWarning = $true
    }

    return $commandParams
}
