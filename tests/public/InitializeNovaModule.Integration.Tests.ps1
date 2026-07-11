. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tests/TestHelpers/PublicCommandIntegration.ps1')

BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Initialize-NovaModule integration' {
    It 'exposes the scaffold entrypoint from the built module' {
        $command = Get-Command -Name 'Initialize-NovaModule'

        $command.Parameters.Keys | Should -Contain 'Path'
        $command.Parameters.Keys | Should -Contain 'Example'
        $command.CmdletBinding | Should -BeTrue
    }
}
