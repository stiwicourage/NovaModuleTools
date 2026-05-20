BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaCopilotCliArgument.ps1')
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliRequiredArgumentValue.ps1')

    . (Join-Path $PSScriptRoot 'ConvertFromNovaInitCliArgument.TestSupport.ps1')
}

Describe 'ConvertFrom-NovaCopilotCliArgument' {
    It 'reads path and short-name values' {
        $options = ConvertFrom-NovaCopilotCliArgument -Arguments @('--path', '/tmp/x', '--short-name', 'NMT')
        $options.Path | Should -Be '/tmp/x'
        $options.ShortName | Should -Be 'NMT'
    }

    It 'sets override-warning, what-if, and verbose switches' {
        $options = ConvertFrom-NovaCopilotCliArgument -Arguments @('--override-warning', '--what-if', '--verbose')
        $options.OverrideWarning | Should -BeTrue
        $options.WhatIf | Should -BeTrue
        $options.Verbose | Should -BeTrue
    }

    It 'supports -o as a short alias for override-warning' {
        $options = ConvertFrom-NovaCopilotCliArgument -Arguments @('-o')
        $options.OverrideWarning | Should -BeTrue
    }

    It 'throws for unknown switches' {
        {ConvertFrom-NovaCopilotCliArgument -Arguments @('--bogus')} | Should -Throw '*Unknown argument*'
    }
}
