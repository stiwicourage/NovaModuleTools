function Publish-NovaModule {
    [CmdletBinding(DefaultParameterSetName = 'Local', SupportsShouldProcess = $true)]
    param(
        [Parameter(ParameterSetName = 'Local')]
        [switch]$Local,

        [Parameter(ParameterSetName = 'Repository', Mandatory)]
        [string]$Repository,

        [string]$ModuleDirectoryPath,
        [string]$ApiKey
    )

    $projectInfo = Get-NovaProjectInfo
    $workflowParams = Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:$WhatIfPreference
    $publishInvocation = Resolve-NovaPublishInvocation -ProjectInfo $projectInfo -Repository $Repository -ModuleDirectoryPath $ModuleDirectoryPath -ApiKey $ApiKey

    Write-NovaLocalWorkflowMode -WorkflowName publish -LocalRequested:$Local
    Write-NovaResolvedLocalPublishTarget -PublishInvocation $publishInvocation

    $publishOperation = Get-NovaPublishWorkflowOperation -IsLocal:$publishInvocation.IsLocal

    $shouldRun = $PSCmdlet.ShouldProcess($publishInvocation.Target, $publishOperation)
    if (-not $shouldRun -and -not $WhatIfPreference) {
        return
    }

    Invoke-NovaBuild @workflowParams
    Test-NovaBuild @workflowParams

    Invoke-NovaResolvedPublishInvocation -PublishInvocation $publishInvocation -WorkflowParams $workflowParams

    Write-NovaLocalPublishCompletionMessage -ShouldRun:$shouldRun -PublishInvocation $publishInvocation
}


