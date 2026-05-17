BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaReleaseRequest.ps1')
}

Describe 'Get-NovaReleaseRequestedPath' {
    It 'returns the bound Path when set' {
        Get-NovaReleaseRequestedPath -BoundParameters @{Path='/p'} | Should -Be '/p'
    }

    It 'falls back to current location when Path is not bound' {
        Get-NovaReleaseRequestedPath -BoundParameters @{} | Should -Be (Get-Location).Path
    }
}

Describe 'Get-NovaReleaseBoundValueOrDefault' {
    It 'returns the bound value when present' {
        Get-NovaReleaseBoundValueOrDefault -BoundParameters @{Name='a'} -Name 'Name' -DefaultValue 'fallback' | Should -Be 'a'
    }

    It 'returns the default value when absent' {
        Get-NovaReleaseBoundValueOrDefault -BoundParameters @{} -Name 'Name' -DefaultValue 'fallback' | Should -Be 'fallback'
    }
}

Describe 'Test-NovaReleaseBoundSwitch' {
    It 'returns true when the switch is bound to true' {
        Test-NovaReleaseBoundSwitch -BoundParameters @{Local=$true} -Name 'Local' | Should -BeTrue
    }

    It 'returns false when the switch is absent' {
        Test-NovaReleaseBoundSwitch -BoundParameters @{} -Name 'Local' | Should -BeFalse
    }
}

Describe 'Get-NovaReleaseRequest' {
    It 'composes a full release request from bound parameters' {
        $req = Get-NovaReleaseRequest -BoundParameters @{Local=$true; Repository='r'; SkipTests=$true} -ParameterSetName 'Repository'
        $req.ParameterSetName | Should -Be 'Repository'
        $req.LocalRequested | Should -BeTrue
        $req.Repository | Should -Be 'r'
        $req.SkipTestsRequested | Should -BeTrue
        $req.ContinuousIntegrationRequested | Should -BeFalse
    }
}
