BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/UpdateNovaModuleTools.ps1')

    . (Join-Path $PSScriptRoot 'UpdateNovaModuleTools.TestSupport.ps1')
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
