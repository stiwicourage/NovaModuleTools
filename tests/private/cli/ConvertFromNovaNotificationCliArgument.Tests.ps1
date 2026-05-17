BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaNotificationCliArgument.ps1')

    function Get-NovaCliModeArgumentValue {param([string[]]$Arguments, [pscustomobject]$Definition) return $Definition}
}

Describe 'ConvertFrom-NovaNotificationCliArgument' {
    It 'declares notification token mappings and default status mode' {
        $definition = ConvertFrom-NovaNotificationCliArgument -Arguments @()
        $definition.EmptyResult | Should -Be 'status'
        $definition.TokenMap['--enable'] | Should -Be 'enable'
        $definition.TokenMap['-e'] | Should -Be 'enable'
        $definition.TokenMap['--disable'] | Should -Be 'disable'
        $definition.UnknownArgumentUsesUsageError | Should -BeFalse
    }
}
