BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaBumpCliArgument.ps1')

    function ConvertFrom-NovaCliSwitchArgument {param([string[]]$Arguments, [hashtable]$TokenMap) return $TokenMap}
}

Describe 'ConvertFrom-NovaBumpCliArgument' {
    It 'maps bump switches to canonical options' {
        $tokenMap = ConvertFrom-NovaBumpCliArgument -Arguments @()
        $tokenMap['--preview'] | Should -Be 'Preview'
        $tokenMap['-p'] | Should -Be 'Preview'
        $tokenMap['--continuous-integration'] | Should -Be 'ContinuousIntegration'
        $tokenMap['--override-warning'] | Should -Be 'OverrideWarning'
    }
}
