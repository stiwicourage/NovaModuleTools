BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaVersionCliArgument.ps1')

    function Get-NovaCliModeArgumentValue {param([string[]]$Arguments, [pscustomobject]$Definition) return $Definition}
}

Describe 'ConvertFrom-NovaVersionCliArgument' {
    It 'declares the --installed token map' {
        $definition = ConvertFrom-NovaVersionCliArgument -Arguments @()
        $definition.EmptyResult.Installed | Should -BeFalse
        $definition.TokenMap['--installed'].Installed | Should -BeTrue
        $definition.TokenMap['-i'].Installed | Should -BeTrue
        $definition.UnknownArgumentUsesUsageError | Should -BeTrue
    }
}
