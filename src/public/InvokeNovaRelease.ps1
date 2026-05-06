function Invoke-NovaRelease {
    [CmdletBinding(DefaultParameterSetName = 'Local', SupportsShouldProcess = $true)]
    param(
        [Parameter(ParameterSetName = 'Local')]
        [switch]$Local,

        [Parameter(ParameterSetName = 'Repository', Mandatory)]
        [string]$Repository,

        [Parameter(ParameterSetName = 'Local')]
        [Parameter(ParameterSetName = 'Repository')]
        [string]$ModuleDirectoryPath,

        [Parameter(ParameterSetName = 'Local')]
        [Parameter(ParameterSetName = 'Repository')]
        [string]$ApiKey
    )

    dynamicparam {
        return Get-NovaDynamicReleaseParameterDictionary
    }

    begin {
        $path = Get-NovaReleaseRequestedPath -BoundParameters $PSBoundParameters

        # TODO: Remove legacy PublishOption compatibility after 2026-07-01.
        $releasePublishOption = Get-NovaReleasePublishOption -ReleaseParameters (Get-NovaReleaseRequest -BoundParameters $PSBoundParameters -ParameterSetName $PSCmdlet.ParameterSetName)

        Push-Location -LiteralPath $path
        try {
            $workflowContext = Get-NovaPublishWorkflowContext -ProjectInfo (Get-NovaProjectInfo) -PublishOption $releasePublishOption -WorkflowParams (Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:$WhatIfPreference) -WorkflowSettings @{
                WorkflowName = 'release'
                Release = $true
            }

            Write-NovaPublishWorkflowContext -WorkflowContext $workflowContext

            $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)
            if (-not $shouldRun -and -not $WhatIfPreference) {
                return
            }

            return Invoke-NovaReleaseWorkflow -WorkflowContext $workflowContext
        }
        finally {
            Pop-Location
        }
    }
}
