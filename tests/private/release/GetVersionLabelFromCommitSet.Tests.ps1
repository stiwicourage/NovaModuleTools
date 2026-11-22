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

    It 'returns Major for a BREAKING-CHANGE footer' {
        Get-VersionLabelFromCommitSet -Messages @("fix: adjust parser`n`nBREAKING-CHANGE: input format changed") | Should -Be 'Major'
    }

    It 'returns Major for scoped ! syntax' {
        Get-VersionLabelFromCommitSet -Messages @('refactor(api)!: rename endpoint') | Should -Be 'Major'
    }

    It 'ignores breaking change wording in the subject' {
        Get-VersionLabelFromCommitSet -Messages @('docs: explain why this is not a breaking change') | Should -Be 'Patch'
    }

    It 'ignores breaking change wording inside the body' {
        Get-VersionLabelFromCommitSet -Messages @("feat: add option`n`nThis avoids a BREAKING CHANGE for callers.") | Should -Be 'Minor'
    }

    It 'ignores a lowercase breaking change footer' {
        Get-VersionLabelFromCommitSet -Messages @("feat: add option`n`nbreaking change: none") | Should -Be 'Minor'
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
