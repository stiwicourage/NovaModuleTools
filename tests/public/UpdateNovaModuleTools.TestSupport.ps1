function Get-NovaShouldProcessForwardingParameter {param([switch]$WhatIfEnabled) return @{WhatIf = [bool]$WhatIfEnabled}}
function Get-NovaModuleSelfUpdateWorkflowContext {param([hashtable]$WorkflowParams) $script:workflowParams = $WorkflowParams; return [pscustomobject]@{Plan=$script:plan; Action='Update'; WorkflowParams=$WorkflowParams}}
function Confirm-NovaPrereleaseModuleUpdate {param($Cmdlet, $CurrentVersion, $TargetVersion) $script:confirmCallCount += 1; return $script:confirmResult}
function Invoke-NovaModuleSelfUpdateWorkflow {param($WorkflowContext, [switch]$ShouldRun)
    $script:invoked = $true
    $script:workflowContext = $WorkflowContext
    $script:shouldRun = [bool]$ShouldRun
    $releaseNotesUri = if ($ShouldRun) {'https://x/rel'} else {$null}
    $WorkflowContext.Plan | Add-Member -NotePropertyName 'ReleaseNotesUri' -NotePropertyValue $releaseNotesUri -Force

    return $WorkflowContext.Plan
}
function Write-NovaModuleReleaseNotesLink {param($ReleaseNotesUri) $script:notesUri = $ReleaseNotesUri}
