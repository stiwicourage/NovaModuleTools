BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaShouldProcessForwardingParameter.ps1')
}

Describe 'Get-NovaShouldProcessForwardingParameter' {
    It 'returns an empty hashtable when WhatIf is not requested' {
        $result = Get-NovaShouldProcessForwardingParameter

        $result | Should -BeOfType [hashtable]
        $result.Keys.Count | Should -Be 0
    }

    It 'forwards WhatIf when requested' {
        $result = Get-NovaShouldProcessForwardingParameter -WhatIfEnabled

        $result.WhatIf | Should -BeTrue
    }
}
