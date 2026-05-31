BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Get-NovaProjectInfo integration' {
    It 'returns project metadata from the built module' {
        $result = Invoke-NovaPublicCommandIntegrationInProjectRoot -ProjectRoot $script:projectRoot -ScriptBlock {
            Get-NovaProjectInfo
        }

        $result.ProjectName | Should -Be 'NovaModuleTools'
    }
}
