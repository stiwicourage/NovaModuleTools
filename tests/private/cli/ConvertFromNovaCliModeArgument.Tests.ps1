BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaCliModeArgument.ps1')

    function ConvertTo-NovaCliArgumentArray {param([hashtable]$BoundParameters, [string[]]$Arguments) return ,@(@($Arguments) | Where-Object {$_})}
    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Get-NovaCliModeArgumentValue' {
    BeforeEach {
        $script:def = [pscustomobject]@{
            EmptyResult = 'empty'
            TokenMap = @{'--on' = 'on'; '--off' = 'off'}
            Usage = [pscustomobject]@{Message = 'usage failure'; ErrorId = 'Nova.Test.Usage'}
            UnknownArgumentUsesUsageError = $true
        }
    }

    It 'returns EmptyResult when no arguments are provided' {
        Get-NovaCliModeArgumentValue -Arguments @() -Definition $script:def | Should -Be 'empty'
    }

    It 'returns the mapped token value for a known argument' {
        Get-NovaCliModeArgumentValue -Arguments @('--on') -Definition $script:def | Should -Be 'on'
    }

    It 'throws the usage error when too many arguments are given' {
        {Get-NovaCliModeArgumentValue -Arguments @('--on', '--off') -Definition $script:def} | Should -Throw '*usage failure*'
    }

    It 'throws the usage error for unknown arguments when configured' {
        {Get-NovaCliModeArgumentValue -Arguments @('--unknown') -Definition $script:def} | Should -Throw '*usage failure*'
    }

    It 'throws a generic unknown argument error when usage routing is disabled' {
        $script:def.UnknownArgumentUsesUsageError = $false
        {Get-NovaCliModeArgumentValue -Arguments @('--bogus') -Definition $script:def} | Should -Throw '*Unknown argument: --bogus*'
    }
}
