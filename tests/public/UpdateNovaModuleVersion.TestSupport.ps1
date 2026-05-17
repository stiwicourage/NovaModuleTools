function Invoke-NovaVersionUpdateCiActivation {param($ProjectRoot, $Parameters, [switch]$ContinuousIntegration, [switch]$WhatIfEnabled)
    return $script:ciActivation
}
function Get-NovaVersionUpdateWorkflowContext {param($ProjectRoot, [switch]$PreviewRelease, [switch]$ContinuousIntegrationRequested, [switch]$OverrideWarningRequested)
    $script:ctxArgs = @{Preview=[bool]$PreviewRelease; CI=[bool]$ContinuousIntegrationRequested; Override=[bool]$OverrideWarningRequested}
    return [pscustomobject]@{Target=$ProjectRoot; Action='Bump'}
}
function Invoke-NovaVersionUpdateWorkflow {param($WorkflowContext, [switch]$ShouldRun, [switch]$WhatIfEnabled)
    $script:invoked = $true
    return $script:workflowResult
}
function Write-NovaVersionUpdateResultOutput {param($Result) $script:outputResult = $Result}
