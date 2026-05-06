function Get-NovaBuildCommandParameterMap {
    [CmdletBinding()]
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
