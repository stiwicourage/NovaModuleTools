BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetVersionLabelFromCommitSet.ps1')
}

Describe 'Get-VersionLabelFromCommitSet' {
    It 'returns Major for breaking change footers' {
        Get-VersionLabelFromCommitSet -Messages @('feat: add x', 'BREAKING CHANGE: remove old') | Should -Be 'Major'
    }

    It 'returns Major for ! syntax' {
        Get-VersionLabelFromCommitSet -Messages @('feat!: drop legacy') | Should -Be 'Major'
    }

    It 'returns Minor for a feat commit' {
        Get-VersionLabelFromCommitSet -Messages @('feat: add x') | Should -Be 'Minor'
    }

    It 'returns Patch for a fix commit' {
        Get-VersionLabelFromCommitSet -Messages @('fix: a bug') | Should -Be 'Patch'
    }

    It 'defaults to Patch when nothing matches' {
        Get-VersionLabelFromCommitSet -Messages @('chore: cleanup') | Should -Be 'Patch'
    }
}
