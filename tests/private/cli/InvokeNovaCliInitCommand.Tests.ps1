BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/InvokeNovaCliInitCommand.ps1')

    function ConvertFrom-NovaInitCliArgument {param([string[]]$Arguments) return @{Path = '/tmp/proj'}}
    function Initialize-NovaModule {param($Path, $Verbose) return [pscustomobject]@{Path = $Path; Verbose = $Verbose}}
    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
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
