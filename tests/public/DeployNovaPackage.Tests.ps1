BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/DeployNovaPackage.ps1')

    . (Join-Path $PSScriptRoot 'DeployNovaPackage.TestSupport.ps1')
}

Describe 'Deploy-NovaPackage' {
    BeforeEach {
        $script:invoked = $false
        $script:wroteContext = $false
        $script:wroteResult = $false
    }

    It 'writes context, invokes the upload workflow, and returns its results' {
        $result = Deploy-NovaPackage -PackagePath '/o/a.nupkg' -Url 'https://x' -Repository 'Nexus'
        $script:wroteContext | Should -BeTrue
        $script:invoked | Should -BeTrue
        $script:wroteResult | Should -BeTrue
        @($result).Count | Should -Be 1
        $result[0].StatusCode | Should -Be 201
    }

    It 'writes context and returns an empty array without invoking the workflow when -WhatIf is set' {
        $result = Deploy-NovaPackage -PackagePath '/o/a.nupkg' -WhatIf
        $script:wroteContext | Should -BeTrue
        $script:invoked | Should -BeFalse
        $script:wroteResult | Should -BeFalse
        @($result).Count | Should -Be 0
    }
}
