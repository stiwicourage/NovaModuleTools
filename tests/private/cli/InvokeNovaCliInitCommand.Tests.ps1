BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/InvokeNovaCliInitCommand.ps1')

    . (Join-Path $PSScriptRoot 'InvokeNovaCliInitCommand.TestSupport.ps1')
}

Describe 'Invoke-NovaCliInitCommand' {
    It 'forwards parsed options and parameters into Initialize-NovaModule' {
        $result = Invoke-NovaCliInitCommand -Arguments @('--path', '/tmp/proj') -ForwardedParameters @{Verbose = $true}
        $result.Path | Should -Be '/tmp/proj'
        $result.Verbose | Should -BeTrue
    }

    It 'rejects --what-if usage' {
        {Invoke-NovaCliInitCommand -Arguments @() -ForwardedParameters @{} -WhatIfEnabled} | Should -Throw '*does not support*'
    }
}
