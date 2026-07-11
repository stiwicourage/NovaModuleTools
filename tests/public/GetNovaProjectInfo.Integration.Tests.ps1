. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tests/TestHelpers/PublicCommandIntegration.ps1')

BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Get-NovaProjectInfo integration' {
    It 'returns project metadata from the built module' {
        Push-Location -LiteralPath $script:projectRoot
        try {
            $result = Get-NovaProjectInfo
        } finally {
            Pop-Location
        }

        $result.ProjectName | Should -Be 'NovaModuleTools'
    }
}
