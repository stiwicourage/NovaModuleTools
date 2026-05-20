BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliArgumentRoutingState.ps1')
    . (Join-Path $projectRoot 'src/private/cli/InvokeNovaCliCopilotCommand.ps1')
    . (Join-Path $PSScriptRoot 'InvokeNovaCliCopilotCommand.TestSupport.ps1')
}

Describe 'Invoke-NovaCliCopilotCommand' {
    It 'merges parsed options with forwarded common parameters' {
        $result = Invoke-NovaCliCopilotCommand -Arguments @('--short-name', 'NMT') -CommonParameters @{Verbose = $true} -MutatingCommonParameters @{WhatIf = $true}

        $result.Path | Should -Be '/tmp/repo'
        $result.ShortName | Should -Be 'NMT'
        $result.Verbose | Should -BeTrue
        $result.WhatIf | Should -BeTrue
    }
}
