function Get-NovaDynamicDeliveryParameterDictionary {return New-Object 'System.Management.Automation.RuntimeDefinedParameterDictionary'}
function Get-NovaProjectInfo {return [pscustomobject]@{Name='X'}}
function Get-NovaShouldProcessForwardingParameter {param([switch]$WhatIfEnabled) return @{WhatIf=[bool]$WhatIfEnabled}}
function Get-NovaPublishWorkflowContext {param($ProjectInfo, $PublishOption, $WorkflowParams, $WorkflowSettings)
    $script:publishOption = $PublishOption
    $script:settings = $WorkflowSettings
    return [pscustomobject]@{Target='nuget.org'; Operation='Publish'}
}
function Write-NovaPublishWorkflowContext {param($WorkflowContext) $script:wrote = $true}
function Invoke-NovaPublishWorkflow {param($WorkflowContext, [switch]$ShouldRun)
    $script:invoked = $true
    $script:shouldRun = [bool]$ShouldRun
}
