BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaInitCliArgument.ps1')
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliRequiredArgumentValue.ps1')

    . (Join-Path $PSScriptRoot 'ConvertFromNovaInitCliArgument.TestSupport.ps1')
}

Describe 'ConvertFrom-NovaInitCliArgument' {
    It 'reads --path value' {
        $options = ConvertFrom-NovaInitCliArgument -Arguments @('--path', '/tmp/x')
        $options.Path | Should -Be '/tmp/x'
    }

    It 'sets Example when --example/-e provided' {
        (ConvertFrom-NovaInitCliArgument -Arguments @('-e')).Example | Should -BeTrue
    }

    It 'throws for unknown switches' {
        {ConvertFrom-NovaInitCliArgument -Arguments @('--bogus')} | Should -Throw '*Unknown argument*'
    }

    It 'rejects positional path tokens with a guided message' {
        {ConvertFrom-NovaInitCliArgument -Arguments @('positional')} | Should -Throw '*positional paths are no longer accepted*'
    }
}
