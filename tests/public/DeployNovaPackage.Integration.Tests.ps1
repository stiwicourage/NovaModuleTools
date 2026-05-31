BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Deploy-NovaPackage integration' {
    It 'supports WhatIf from the built module' {
        $packagePath = Join-Path $TestDrive 'NovaModuleTools.0.0.0.nupkg'
        Set-Content -LiteralPath $packagePath -Value 'placeholder'

        $result = Invoke-NovaPublicCommandIntegrationInProjectRoot -ProjectRoot $script:projectRoot -ScriptBlock {
            Deploy-NovaPackage -PackagePath $packagePath -Url 'https://example.test' -WhatIf
        }

        @($result).Count | Should -Be 0
    }
}
