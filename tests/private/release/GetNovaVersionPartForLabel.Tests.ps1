BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaVersionPartForLabel.ps1')
}

Describe 'Get-NovaVersionPartObject' {
    It 'mirrors current version parts' {
        $parts = Get-NovaVersionPartObject -CurrentVersion ([semver]'1.2.3')
        $parts.Major | Should -Be 1
        $parts.Minor | Should -Be 2
        $parts.Patch | Should -Be 3
    }
}

Describe 'Get-NovaVersionTargetLabelForPrerelease' {
    It 'returns Patch when Patch > 0' {
        Get-NovaVersionTargetLabelForPrerelease -CurrentVersion ([semver]'1.2.3-preview01') | Should -Be 'Patch'
    }

    It 'returns Minor when only Minor > 0' {
        Get-NovaVersionTargetLabelForPrerelease -CurrentVersion ([semver]'1.2.0-preview01') | Should -Be 'Minor'
    }

    It 'returns Major when only Major > 0' {
        Get-NovaVersionTargetLabelForPrerelease -CurrentVersion ([semver]'1.0.0-preview01') | Should -Be 'Major'
    }
}

Describe 'Test-NovaVersionShouldFinalizePrereleaseTarget' {
    It 'returns false when no prerelease label' {
        Test-NovaVersionShouldFinalizePrereleaseTarget -CurrentVersion ([semver]'1.2.3') -Label 'Patch' | Should -BeFalse
    }

    It 'returns true when target label matches prerelease bias' {
        Test-NovaVersionShouldFinalizePrereleaseTarget -CurrentVersion ([semver]'1.2.3-preview01') -Label 'Patch' | Should -BeTrue
    }
}

Describe 'Get-NovaVersionPartForLabel' {
    It 'bumps major when Label=Major' {
        $parts = Get-NovaVersionPartForLabel -CurrentVersion ([semver]'1.2.3') -Label Major
        $parts.Major | Should -Be 2
        $parts.Minor | Should -Be 0
        $parts.Patch | Should -Be 0
    }

    It 'bumps minor when Label=Minor' {
        $parts = Get-NovaVersionPartForLabel -CurrentVersion ([semver]'1.2.3') -Label Minor
        $parts.Minor | Should -Be 3
        $parts.Patch | Should -Be 0
    }

    It 'bumps patch when Label=Patch' {
        $parts = Get-NovaVersionPartForLabel -CurrentVersion ([semver]'1.2.3') -Label Patch
        $parts.Patch | Should -Be 4
    }

    It 'finalizes a prerelease without incrementing the part' {
        $parts = Get-NovaVersionPartForLabel -CurrentVersion ([semver]'1.0.0-preview01') -Label Major
        $parts.Major | Should -Be 1
    }
}
