BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliCommandHelp.ps1')

    function Get-NovaCliCommandHelpDefinition {param([string]$Command) return @{Definition = $Command}}
    function Format-NovaCliCommandHelp {param($Definition, [string]$View) return "$View|$($Definition.Definition)"}
}

Describe 'Test-NovaCliHelpToken' {
    It 'matches --help' {Test-NovaCliHelpToken -Argument '--help' | Should -BeTrue}
    It 'matches -h' {Test-NovaCliHelpToken -Argument '-h' | Should -BeTrue}
    It 'rejects other tokens' {Test-NovaCliHelpToken -Argument '--build' | Should -BeFalse}
}

Describe 'Get-NovaCliCommandHelp' {
    It 'formats the resolved definition using the requested view' {
        Get-NovaCliCommandHelp -Command 'build' -View 'Long' | Should -Be 'Long|build'
    }

    It 'defaults to Short view' {
        Get-NovaCliCommandHelp -Command 'build' | Should -Be 'Short|build'
    }
}
