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
        $path = if ( $PSBoundParameters.ContainsKey('Path')) {
            $PSBoundParameters.Path
        }
        else {
            (Get-Location).Path
        }

        # TODO: Remove legacy PublishOption compatibility after 2026-07-01.
        $releasePublishOption = Get-NovaReleasePublishOption -ReleaseParameters ([pscustomobject]@{
            ParameterSetName = $PSCmdlet.ParameterSetName
            PublishOption = if ( $PSBoundParameters.ContainsKey('PublishOption')) {
                $PSBoundParameters.PublishOption
            }
            else {
                @{}
            }
            LocalRequested = [bool]$Local
            Repository = $Repository
            ModuleDirectoryPath = $ModuleDirectoryPath
            ApiKey = $ApiKey
            SkipTestsRequested = $PSBoundParameters.ContainsKey('SkipTests') -and $PSBoundParameters.SkipTests
            ContinuousIntegrationRequested = $PSBoundParameters.ContainsKey('ContinuousIntegration') -and $PSBoundParameters.ContinuousIntegration
        })

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
