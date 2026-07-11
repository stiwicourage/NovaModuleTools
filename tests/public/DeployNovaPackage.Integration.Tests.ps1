. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tests/TestHelpers/PublicCommandIntegration.ps1')

BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Deploy-NovaPackage integration' {
    It 'supports WhatIf from the built module' {
        $packagePath = Join-Path $TestDrive 'NovaModuleTools.0.0.0.nupkg'
        Set-Content -LiteralPath $packagePath -Value 'placeholder'

        Push-Location -LiteralPath $script:projectRoot
        try {
            $result = Deploy-NovaPackage -PackagePath $packagePath -Url 'https://example.test' -WhatIf
        } finally {
            Pop-Location
        }

        @($result).Count | Should -Be 0
    }
}
