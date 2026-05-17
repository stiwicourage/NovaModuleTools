function Get-NovaDynamicReleaseParameterDictionary {return New-Object 'System.Management.Automation.RuntimeDefinedParameterDictionary'}
function Get-NovaReleaseRequestedPath {param($BoundParameters) return (Get-Location).Path}
function Get-NovaReleaseRequest {param($BoundParameters, $ParameterSetName)
    $script:parameterSet = $ParameterSetName
    return [pscustomobject]@{ParameterSetName=$ParameterSetName}
}
function Get-NovaReleasePublishOption {param($ReleaseParameters) return [pscustomobject]@{Local=$true}}
function Get-NovaProjectInfo {return [pscustomobject]@{Name='X'}}
function Get-NovaShouldProcessForwardingParameter {param([switch]$WhatIfEnabled) return @{WhatIf=[bool]$WhatIfEnabled}}
function Get-NovaPublishWorkflowContext {param($ProjectInfo, $PublishOption, $WorkflowParams, $WorkflowSettings)
    $script:settings = $WorkflowSettings
    return [pscustomobject]@{Target='nuget.org'; Operation='Release'}
}
function Write-NovaPublishWorkflowContext {param($WorkflowContext) $script:wrote = $true}
function Invoke-NovaReleaseWorkflow {param($WorkflowContext)
    $script:invoked = $true
    return [pscustomobject]@{Released=$true}
}
