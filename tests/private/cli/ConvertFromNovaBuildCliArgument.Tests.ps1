BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaBuildCliArgument.ps1')

    function ConvertFrom-NovaCliSwitchArgument {param([string[]]$Arguments, [hashtable]$TokenMap) return @{TokenMap = $TokenMap; Arguments = $Arguments}}
}

Describe 'ConvertFrom-NovaBuildCliArgument' {
    It 'maps build switches to canonical options' {
        $result = ConvertFrom-NovaBuildCliArgument -Arguments @('-i')
        $result.TokenMap['--continuous-integration'] | Should -Be 'ContinuousIntegration'
        $result.TokenMap['-o'] | Should -Be 'OverrideWarning'
        $result.TokenMap['--override-warning'] | Should -Be 'OverrideWarning'
    }
}
