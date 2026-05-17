function Get-NovaShouldProcessForwardingParameter {param([switch]$WhatIfEnabled) return @{WhatIf=[bool]$WhatIfEnabled}}
function Get-NovaPackageWorkflowContext {param($WorkflowParams, [switch]$SkipTestsRequested, [switch]$OverrideWarningRequested)
    $script:ctxArgs = @{SkipTests=[bool]$SkipTestsRequested; Override=[bool]$OverrideWarningRequested}
    return [pscustomobject]@{Target='/proj'; Operation='Package'}
}
function Invoke-NovaPackageWorkflow {param($WorkflowContext, [switch]$ShouldRun)
    $script:shouldRun = [bool]$ShouldRun
    return 'packaged'
}
