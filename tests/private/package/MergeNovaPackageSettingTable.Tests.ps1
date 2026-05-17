BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/MergeNovaPackageSettingTable.ps1')
}

Describe 'Get-NovaPackageSettingEntryList' {
    It 'returns empty for null' {
        @(Get-NovaPackageSettingEntryList -Settings $null).Count | Should -Be 0
    }

    It 'returns entries from a dictionary' {
        $entries = Get-NovaPackageSettingEntryList -Settings @{A=1; B=2}
        @($entries).Count | Should -Be 2
    }

    It 'returns entries from an object' {
        $entries = Get-NovaPackageSettingEntryList -Settings ([pscustomobject]@{A=1})
        $entries[0].Name | Should -Be 'A'
        $entries[0].Value | Should -Be 1
    }
}

Describe 'Get-NovaDictionaryEntryList' {
    It 'projects each key/value' {
        $entries = Get-NovaDictionaryEntryList -Dictionary @{A=1}
        $entries[0].Name | Should -Be 'A'
    }
}

Describe 'Merge-NovaPackageSettingTable' {
    It 'merges base and override into an ordered dictionary' {
        $merged = Merge-NovaPackageSettingTable -BaseSettings @{A=1; B=2} -OverrideSettings @{B=3; C=4}
        $merged['A'] | Should -Be 1
        $merged['B'] | Should -Be 3
        $merged['C'] | Should -Be 4
    }

    It 'returns an empty ordered dictionary when both inputs are null' {
        $merged = Merge-NovaPackageSettingTable -BaseSettings $null -OverrideSettings $null
        @($merged.Keys).Count | Should -Be 0
    }
}
