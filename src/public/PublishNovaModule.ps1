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

    dynamicparam {
        return Get-NovaDynamicSkipTestsParameterDictionary
    }

    begin {
        $skipTests = $PSBoundParameters.ContainsKey('SkipTests') -and $PSBoundParameters.SkipTests

        $workflowContext = Get-NovaPublishWorkflowContext -ProjectInfo (Get-NovaProjectInfo) -PublishOption @{
            Local = [bool]$Local
            Repository = $Repository
            ModuleDirectoryPath = $ModuleDirectoryPath
            ApiKey = $ApiKey
            SkipTests = [bool]$skipTests
        } -WorkflowParams (Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:$WhatIfPreference) -WorkflowSettings @{
            WorkflowName = 'publish'
            IncludeLocalPublishActivation = $true
        }

        Write-NovaPublishWorkflowContext -WorkflowContext $workflowContext

        $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)
        if (-not $shouldRun -and -not $WhatIfPreference) {
            return
        }

        Invoke-NovaPublishWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun
    }
}
