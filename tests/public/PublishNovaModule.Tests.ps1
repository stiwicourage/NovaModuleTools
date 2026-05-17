BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/PublishNovaModule.ps1')

    . (Join-Path $PSScriptRoot 'PublishNovaModule.TestSupport.ps1')
}

Describe 'Publish-NovaModule' {
    BeforeEach {
        $script:publishOption = $null; $script:settings = $null
        $script:wrote = $false; $script:invoked = $false; $script:shouldRun = $null
    }

    It 'builds the local publish option and invokes the publish workflow' {
        Publish-NovaModule -Local
        $script:publishOption.Local | Should -BeTrue
        $script:settings.WorkflowName | Should -Be 'publish'
        $script:settings.IncludeLocalPublishActivation | Should -BeTrue
        $script:wrote | Should -BeTrue
        $script:invoked | Should -BeTrue
    }

    It 'invokes the publish workflow with ShouldRun=$false when -WhatIf is set' {
        Publish-NovaModule -Local -WhatIf
        $script:invoked | Should -BeTrue
        $script:shouldRun | Should -BeFalse
    }

    It 'forwards Repository, ModuleDirectoryPath, and ApiKey to the publish option' {
        Publish-NovaModule -Repository 'Nexus' -ModuleDirectoryPath '/d' -ApiKey 'k'
        $script:publishOption.Repository | Should -Be 'Nexus'
        $script:publishOption.ModuleDirectoryPath | Should -Be '/d'
        $script:publishOption.ApiKey | Should -Be 'k'
    }
}
