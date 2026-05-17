BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/InvokeNovaRelease.ps1')

    . (Join-Path $PSScriptRoot 'InvokeNovaRelease.TestSupport.ps1')
}

Describe 'Invoke-NovaRelease' {
    BeforeEach {
        $script:parameterSet = $null; $script:settings = $null
        $script:wrote = $false; $script:invoked = $false
    }

    It 'runs the release workflow with release-flavored settings' {
        $result = Invoke-NovaRelease -Local
        $script:parameterSet | Should -Be 'Local'
        $script:settings.WorkflowName | Should -Be 'release'
        $script:settings.Release | Should -BeTrue
        $script:wrote | Should -BeTrue
        $script:invoked | Should -BeTrue
        $result.Released | Should -BeTrue
    }

    It 'still invokes the release workflow when -WhatIf is set so it can render its plan' {
        Invoke-NovaRelease -Local -WhatIf | Out-Null
        $script:invoked | Should -BeTrue
    }
}
