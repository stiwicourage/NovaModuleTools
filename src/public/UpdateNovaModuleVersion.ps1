function Update-NovaModuleVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$Path = (Get-Location).Path,
        [switch]$Preview,
        [switch]$ContinuousIntegration
    )

    $projectRoot = (Resolve-Path -LiteralPath $Path).Path
    $ciActivation = Invoke-NovaVersionUpdateCiActivation -ProjectRoot $projectRoot -Parameters $PSBoundParameters -ContinuousIntegration:$ContinuousIntegration -WhatIfEnabled:$WhatIfPreference
    if ($ciActivation.ShouldReturn) {
        return $ciActivation.Result
    }

    $workflowContext = Get-NovaVersionUpdateWorkflowContext -ProjectRoot $projectRoot -PreviewRelease:$Preview -ContinuousIntegrationRequested:$ContinuousIntegration
    $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Action)
    $result = Invoke-NovaVersionUpdateWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun -WhatIfEnabled:$WhatIfPreference
    if ($null -eq $result) {
        return
    }

    Write-NovaVersionUpdateResultOutput -Result $result

    return $result
}

