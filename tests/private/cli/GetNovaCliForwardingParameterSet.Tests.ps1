BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliForwardingParameterSet.ps1')
}

Describe 'Get-NovaCliForwardingParameterSet' {
    It 'forwards Verbose when present' {
        $result = Get-NovaCliForwardingParameterSet -BoundParameters @{Verbose = $true}
        $result.Verbose | Should -BeTrue
        $result.ContainsKey('WhatIf') | Should -BeFalse
    }

    It 'forwards Confirm and WhatIf when IncludeShouldProcess and WhatIfPreference is set' {
        $WhatIfPreference = $true
        $result = Get-NovaCliForwardingParameterSet -BoundParameters @{Confirm = $true} -IncludeShouldProcess
        $result.WhatIf | Should -BeTrue
        $result.Confirm | Should -BeTrue
    }

    It 'omits ShouldProcess parameters when IncludeShouldProcess is not set' {
        $result = Get-NovaCliForwardingParameterSet -BoundParameters @{Confirm = $true}
        $result.ContainsKey('Confirm') | Should -BeFalse
    }
}
