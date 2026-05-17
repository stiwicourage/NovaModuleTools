BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/DeployNovaPackage.ps1')

    . (Join-Path $PSScriptRoot 'DeployNovaPackage.TestSupport.ps1')
}

Describe 'Deploy-NovaPackage' {
    BeforeEach {$script:invoked = $false}

    It 'invokes the upload workflow and returns its results' {
        $result = Deploy-NovaPackage -PackagePath '/o/a.nupkg' -Url 'https://x' -Repository 'Nexus'
        $script:invoked | Should -BeTrue
        @($result).Count | Should -Be 1
        $result[0].StatusCode | Should -Be 201
    }

    It 'returns an empty array and does not invoke the workflow when -WhatIf is set' {
        $result = Deploy-NovaPackage -PackagePath '/o/a.nupkg' -WhatIf
        $script:invoked | Should -BeFalse
        @($result).Count | Should -Be 0
    }
}
