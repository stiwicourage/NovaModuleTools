BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaVersionPreReleaseLabel.ps1')
}

Describe 'Get-NovaInitialPreReleaseNumber' {
    It 'returns 01' {
        Get-NovaInitialPreReleaseNumber | Should -Be '01'
    }
}

Describe 'Get-NovaIncrementedPreReleaseNumber' {
    It 'increments single-digit labels without padding' {
        Get-NovaIncrementedPreReleaseNumber -PreReleaseNumber '3' | Should -Be 4
    }

    It 'pads zero-padded numbers to the same width' {
        Get-NovaIncrementedPreReleaseNumber -PreReleaseNumber '09' | Should -Be '10'
    }
}

Describe 'Get-NovaNextPreReleaseLabel' {
    It 'appends the initial number when no number suffix exists' {
        Get-NovaNextPreReleaseLabel -PreReleaseLabel 'preview' | Should -Be 'preview01'
    }

    It 'increments the existing numeric suffix' {
        Get-NovaNextPreReleaseLabel -PreReleaseLabel 'preview01' | Should -Be 'preview02'
    }
}

Describe 'Get-NovaPreviewReleaseLabel' {
    It 'returns preview when CurrentVersion is null' {
        Get-NovaPreviewReleaseLabel -CurrentVersion $null | Should -Be 'preview'
    }

    It 'returns preview when current version has no PreReleaseLabel' {
        Get-NovaPreviewReleaseLabel -CurrentVersion ([semver]'1.2.3') | Should -Be 'preview'
    }

    It 'returns next preview label when one exists' {
        Get-NovaPreviewReleaseLabel -CurrentVersion ([semver]'1.2.3-preview01') | Should -Be 'preview02'
    }
}

Describe 'Get-NovaVersionPreReleaseLabel' {
    It 'returns preview label for PreviewRelease' {
        Get-NovaVersionPreReleaseLabel -CurrentVersion ([semver]'1.0.0') -PreviewRelease | Should -Be 'preview'
    }

    It 'returns $null for StableRelease' {
        Get-NovaVersionPreReleaseLabel -CurrentVersion ([semver]'1.0.0') -StableRelease | Should -BeNullOrEmpty
    }

    It 'returns $null by default' {
        Get-NovaVersionPreReleaseLabel -CurrentVersion ([semver]'1.0.0') | Should -BeNullOrEmpty
    }
}
