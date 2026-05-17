BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/UpdateNovaModuleTools.ps1')

    function Get-NovaModuleSelfUpdateWorkflowContext {return [pscustomobject]@{Plan=$script:plan; Action='Update'}}
    function Complete-NovaModuleSelfUpdateResult {param($Plan, $ReleaseNotesUri) return [pscustomobject]@{Plan=$Plan; ReleaseNotesUri=$ReleaseNotesUri; Completed=$true}}
    function Confirm-NovaPrereleaseModuleUpdate {param($Cmdlet, $CurrentVersion, $TargetVersion) return $script:confirmResult}
    function Invoke-NovaModuleSelfUpdateWorkflow {param($WorkflowContext)
        $script:invoked = $true
        return [pscustomobject]@{ReleaseNotesUri='https://x/rel'}
    }
    function Write-NovaModuleReleaseNotesLink {param($ReleaseNotesUri) $script:notesUri = $ReleaseNotesUri}
}

Describe 'Update-NovaModuleTool' {
    BeforeEach {
        $script:plan = [pscustomobject]@{UpdateAvailable=$true; IsPrereleaseTarget=$false; ModuleName='NovaModuleTools'; CurrentVersion='1.0.0'; TargetVersion='1.1.0'; Cancelled=$false}
        $script:confirmResult = $true
        $script:invoked = $false; $script:notesUri = $null
    }

    It 'short-circuits with a completion result when no update is available' {
        $script:plan.UpdateAvailable = $false
        $result = Update-NovaModuleTool
        $script:invoked | Should -BeFalse
        $result.Completed | Should -BeTrue
    }

    It 'cancels when a prerelease target is not confirmed' {
        $script:plan.IsPrereleaseTarget = $true
        $script:confirmResult = $false
        $result = Update-NovaModuleTool
        $script:invoked | Should -BeFalse
        $result.Plan.Cancelled | Should -BeTrue
    }

    It 'runs the self-update workflow and writes the release notes link' {
        $result = Update-NovaModuleTool
        $script:invoked | Should -BeTrue
        $script:notesUri | Should -Be 'https://x/rel'
        $result.ReleaseNotesUri | Should -Be 'https://x/rel'
    }
}
