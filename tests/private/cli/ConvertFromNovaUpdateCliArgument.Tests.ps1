BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaUpdateCliArgument.ps1')

    function Get-NovaCliModeArgumentValue {param([string[]]$Arguments, [pscustomobject]$Definition) return $Definition}
}

Describe 'ConvertFrom-NovaUpdateCliArgument' {
    It 'configures an empty token map with an update-specific usage error' {
        $definition = ConvertFrom-NovaUpdateCliArgument -Arguments @()
        $definition.TokenMap.Count | Should -Be 0
        $definition.UnknownArgumentUsesUsageError | Should -BeTrue
        $definition.Usage.ErrorId | Should -Be 'Nova.Validation.UnsupportedUpdateCliUsage'
    }
}
