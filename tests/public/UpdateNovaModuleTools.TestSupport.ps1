function Get-NovaModuleSelfUpdateWorkflowContext {return [pscustomobject]@{Plan=$script:plan; Action='Update'}}
function Complete-NovaModuleSelfUpdateResult {param($Plan, $ReleaseNotesUri) return [pscustomobject]@{Plan=$Plan; ReleaseNotesUri=$ReleaseNotesUri; Completed=$true}}
function Confirm-NovaPrereleaseModuleUpdate {param($Cmdlet, $CurrentVersion, $TargetVersion) return $script:confirmResult}
function Invoke-NovaModuleSelfUpdateWorkflow {param($WorkflowContext)
    $script:invoked = $true
    return [pscustomobject]@{ReleaseNotesUri='https://x/rel'}
}
function Write-NovaModuleReleaseNotesLink {param($ReleaseNotesUri) $script:notesUri = $ReleaseNotesUri}
