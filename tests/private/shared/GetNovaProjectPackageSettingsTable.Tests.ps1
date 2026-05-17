BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaProjectPackageSettingsTable.ps1')
}

Describe 'Get-NovaProjectPackageSettingsTable' {
    It 'returns an empty ordered table when Package is missing' {
        $result = Get-NovaProjectPackageSettingsTable -ProjectData @{}

        $result.Count | Should -Be 0
    }

    It 'returns an empty table when Package is not a hashtable' {
        $result = Get-NovaProjectPackageSettingsTable -ProjectData @{Package = 'not a table'}

        $result.Count | Should -Be 0
    }

    It 'returns the Package settings without the Enabled key' {
        $result = Get-NovaProjectPackageSettingsTable -ProjectData @{Package = @{Enabled = $true; Path = 'p'}}

        $result.Contains('Enabled') | Should -BeFalse
        $result['Path'] | Should -Be 'p'
    }

    It 'falls back from RawRepositoryUrl to RepositoryUrl when missing' {
        $result = Get-NovaProjectPackageSettingsTable -ProjectData @{Package = @{RawRepositoryUrl = 'https://example/raw'}}

        $result['RepositoryUrl'] | Should -Be 'https://example/raw'
    }

    It 'preserves an explicitly configured RepositoryUrl over RawRepositoryUrl' {
        $result = Get-NovaProjectPackageSettingsTable -ProjectData @{Package = @{RepositoryUrl = 'a'; RawRepositoryUrl = 'b'}}

        $result['RepositoryUrl'] | Should -Be 'a'
    }
}
