function Invoke-NovaResolvedPublishInvocation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$PublishInvocation,
        [hashtable]$WorkflowParams = @{}
    )

    $publishParams = @{}
    foreach ($parameterName in $PublishInvocation.Parameters.Keys) {
        $publishParams[$parameterName] = $PublishInvocation.Parameters[$parameterName]
    }

    foreach ($parameterName in $WorkflowParams.Keys) {
        $publishParams[$parameterName] = $WorkflowParams[$parameterName]
    }

    return & $PublishInvocation.Action @publishParams
}

