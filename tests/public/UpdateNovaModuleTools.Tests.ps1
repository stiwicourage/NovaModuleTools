BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/UpdateNovaModuleTools.ps1')

    . (Join-Path $PSScriptRoot 'UpdateNovaModuleTools.TestSupport.ps1')
}

Describe 'Update-NovaModuleTool' {
    BeforeEach {
        $script:plan = [pscustomobject]@{
            UpdateAvailable = $true
            IsPrereleaseTarget = $false
            ModuleName = 'NovaModuleTools'
            CurrentVersion = '1.0.0'
            TargetVersion = '1.1.0'
            Cancelled = $false
            LookupRepository = 'PSGallery'
        }
        $script:confirmResult = $true
        $script:confirmCallCount = 0
        $script:invoked = $false
        $script:notesUri = $null
        $script:shouldRun = $null
        $script:workflowContext = $null
        $script:workflowParams = $null
    }

    It 'invokes the workflow with ShouldRun=$false when no update is available' {
        $script:plan.UpdateAvailable = $false

        $result = Update-NovaModuleTool

        $script:invoked | Should -BeTrue
        $script:shouldRun | Should -BeFalse
        $result.UpdateAvailable | Should -BeFalse
        $script:notesUri | Should -BeNull
    }

    It 'cancels when a prerelease target is not confirmed and still invokes the workflow for the summary' {
        $script:plan.IsPrereleaseTarget = $true
        $script:confirmResult = $false

        $result = Update-NovaModuleTool

        $script:invoked | Should -BeTrue
        $script:confirmCallCount | Should -Be 1
        $script:shouldRun | Should -BeFalse
        $result.Cancelled | Should -BeTrue
        $script:notesUri | Should -BeNull
    }

    It 'runs the self-update workflow and writes the release notes link' {
        $result = Update-NovaModuleTool

        $script:invoked | Should -BeTrue
        $script:shouldRun | Should -BeTrue
        $script:workflowParams.WhatIf | Should -BeFalse
        $script:notesUri | Should -Be 'https://x/rel'
        $result.ReleaseNotesUri | Should -Be 'https://x/rel'
    }

    It 'invokes the workflow with ShouldRun=$false in WhatIf mode without prompting for prerelease confirmation' {
        $script:plan.IsPrereleaseTarget = $true

        Update-NovaModuleTool -WhatIf | Out-Null

        $script:invoked | Should -BeTrue
        $script:shouldRun | Should -BeFalse
        $script:workflowContext.WorkflowParams.WhatIf | Should -BeTrue
        $script:confirmCallCount | Should -Be 0
        $script:notesUri | Should -BeNull
    }
}
