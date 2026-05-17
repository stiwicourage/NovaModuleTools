BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaCliArgument.ps1')
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliRequiredArgumentValue.ps1')

    function ConvertTo-NovaCliArgumentArray {param([hashtable]$BoundParameters, [string[]]$Arguments) return @($Arguments | Where-Object {$_})}
    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Add-NovaCliDeliveryOption' {
    It 'adds the option when allowed' {
        $options = @{}
        Add-NovaCliDeliveryOption -Options $options -AllowedOptionNameList @('Local') -Option ([pscustomobject]@{Name='Local';Value=$true}) -Token '--local'
        $options.Local | Should -BeTrue
    }

    It 'throws when option is not in allowed list' {
        {Add-NovaCliDeliveryOption -Options @{} -AllowedOptionNameList @('Other') -Option ([pscustomobject]@{Name='Local';Value=$true}) -Token '--local'} | Should -Throw '*Unknown argument: --local*'
    }
}

Describe 'ConvertFrom-NovaCliArgument' {
    It 'parses common delivery flags using the default allowed list' {
        $options = ConvertFrom-NovaCliArgument -Arguments @('--local', '--repository', 'feed', '--api-key', 'KEY', '--skip-tests')
        $options.Local | Should -BeTrue
        $options.Repository | Should -Be 'feed'
        $options.ApiKey | Should -Be 'KEY'
        $options.SkipTests | Should -BeTrue
    }

    It 'throws when a flag is not in the allowed list' {
        {ConvertFrom-NovaCliArgument -Arguments @('--local') -AllowedOptionNameList @('Other')} | Should -Throw '*Unknown argument*'
    }

    It 'throws for unknown flags' {
        {ConvertFrom-NovaCliArgument -Arguments @('--bogus')} | Should -Throw '*Unknown argument: --bogus*'
    }
}

Describe 'ConvertFrom-NovaPackageCliArgument' {
    It 'restricts the allowed options to package-relevant flags' {
        $options = ConvertFrom-NovaPackageCliArgument -Arguments @('--skip-tests', '--override-warning')
        $options.SkipTests | Should -BeTrue
        $options.OverrideWarning | Should -BeTrue
    }

    It 'rejects flags outside the package allow list' {
        {ConvertFrom-NovaPackageCliArgument -Arguments @('--local')} | Should -Throw '*Unknown argument*'
    }
}
