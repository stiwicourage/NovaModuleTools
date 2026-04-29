function Update-NovaModuleVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$Path = (Get-Location).Path,
        [switch]$Preview,
        [switch]$ContinuousIntegration
    )

    $projectRoot = (Resolve-Path -LiteralPath $Path).Path
    if ($ContinuousIntegration -and -not $WhatIfPreference) {
        $ciActivatedCommand = Get-NovaVersionUpdateCiActivatedCommand -ProjectRoot $projectRoot
        if ($null -ne $ciActivatedCommand) {
            return & $ciActivatedCommand @PSBoundParameters
        }
    }

    $workflowContext = Get-NovaVersionUpdateWorkflowContext -ProjectRoot $projectRoot -PreviewRelease:$Preview -ContinuousIntegrationRequested:$ContinuousIntegration


    $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Action)

    $result = Invoke-NovaVersionUpdateWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun -WhatIfEnabled:$WhatIfPreference
    if ($null -eq $result) {
        return
    }

    if ($result.Applied) {
        Write-Host "Version bumped to : $( $result.NewVersion )"
    }

    return $result
}
