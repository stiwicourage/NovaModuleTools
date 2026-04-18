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
    $localPublishActivation = Get-NovaLocalPublishActivation -PublishInvocation $publishInvocation
    $publishParams = Get-NovaResolvedPublishParameterMap -PublishInvocation $publishInvocation -WorkflowParams $workflowParams

    $shouldRun = $PSCmdlet.ShouldProcess($publishInvocation.Target, $publishOperation)
    if (-not $shouldRun -and -not $WhatIfPreference) {
        return
    }

    Invoke-NovaBuild @workflowParams
    Test-NovaBuild @workflowParams

    & $publishInvocation.Action @publishParams

    if ($shouldRun -and $localPublishActivation) {
        $null = & $localPublishActivation.ImportAction -ProjectName $projectInfo.ProjectName -ManifestPath $localPublishActivation.ManifestPath
        Write-Verbose "Module copy to local path complete and imported from $( $localPublishActivation.ManifestPath )"
    }
}
