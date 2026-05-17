BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/NewNovaModulePackage.ps1')

    . (Join-Path $PSScriptRoot 'NewNovaModulePackage.TestSupport.ps1')
}

Describe 'New-NovaModulePackage' {
    BeforeEach {$script:ctxArgs = $null; $script:shouldRun = $null}

    It 'forwards switch parameters to the workflow context and returns the workflow result' {
        $result = New-NovaModulePackage -SkipTests -OverrideWarning
        $script:ctxArgs.SkipTests | Should -BeTrue
        $script:ctxArgs.Override | Should -BeTrue
        $script:shouldRun | Should -BeTrue
        $result | Should -Be 'packaged'
    }

    It 'passes ShouldRun=$false when -WhatIf is set' {
        New-NovaModulePackage -WhatIf | Out-Null
        $script:shouldRun | Should -BeFalse
    }
}
