BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliRequiredArgumentValue.ps1')

    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Get-NovaCliRequiredArgumentValue' {
    It 'returns the next argument value and advances the index' {
        $index = 0
        $value = Get-NovaCliRequiredArgumentValue -Arguments @('--path', '/tmp/x') -Index ([ref]$index) -OptionName '--path'
        $value | Should -Be '/tmp/x'
        $index | Should -Be 1
    }

    It 'throws when the option has no following value' {
        $index = 0
        {Get-NovaCliRequiredArgumentValue -Arguments @('--path') -Index ([ref]$index) -OptionName '--path'} | Should -Throw '*Missing value for --path*'
    }
}
