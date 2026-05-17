BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaFirstConfiguredValue.ps1')
}

Describe 'Get-NovaFirstConfiguredValue' {
    It 'returns the first non-null, non-empty candidate' {
        Get-NovaFirstConfiguredValue -CandidateList @($null, '', '  ', 'real', 'second') | Should -Be 'real'
    }

    It 'returns $null when all candidates are empty or whitespace strings' {
        Get-NovaFirstConfiguredValue -CandidateList @($null, '', '   ') | Should -BeNullOrEmpty
    }

    It 'returns $null for an empty candidate list' {
        Get-NovaFirstConfiguredValue -CandidateList @() | Should -BeNullOrEmpty
    }

    It 'treats non-string non-null values as configured' {
        Get-NovaFirstConfiguredValue -CandidateList @($null, 0) | Should -Be 0
    }
}

Describe 'Test-NovaConfiguredValue' {
    It 'returns false for $null' {
        Test-NovaConfiguredValue -Value $null | Should -BeFalse
    }

    It 'returns false for whitespace-only string' {
        Test-NovaConfiguredValue -Value '   ' | Should -BeFalse
    }

    It 'returns true for a non-empty string' {
        Test-NovaConfiguredValue -Value 'x' | Should -BeTrue
    }

    It 'returns true for non-string values such as numbers' {
        Test-NovaConfiguredValue -Value 0 | Should -BeTrue
    }
}
