BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaTestCliArgument.ps1')

    function ConvertFrom-NovaCliSwitchArgument {param([string[]]$Arguments, [hashtable]$TokenMap) return $TokenMap}
}

Describe 'ConvertFrom-NovaTestCliArgument' {
    It 'maps test switches to canonical options' {
        $tokenMap = ConvertFrom-NovaTestCliArgument -Arguments @()
        $tokenMap['--build'] | Should -Be 'Build'
        $tokenMap['-b'] | Should -Be 'Build'
        $tokenMap['--override-warning'] | Should -Be 'OverrideWarning'
    }
}
