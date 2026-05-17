BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaProjectPackageOutputDirectorySettingsTable.ps1')
}

Describe 'Get-NovaProjectPackageOutputDirectorySettingsTable' {
    It 'returns a table with $null Path when OutputDirectory is missing' {
        $result = Get-NovaProjectPackageOutputDirectorySettingsTable -PackageSettings ([ordered]@{})

        $result['Path'] | Should -BeNullOrEmpty
    }

    It 'returns a clone of OutputDirectory when it is a dictionary' {
        $packageSettings = [ordered]@{OutputDirectory = [ordered]@{Path = 'p'; Clean = $true}}

        $result = Get-NovaProjectPackageOutputDirectorySettingsTable -PackageSettings $packageSettings

        $result['Path'] | Should -Be 'p'
        $result['Clean'] | Should -BeTrue
    }

    It 'wraps a scalar OutputDirectory value as Path' {
        $result = Get-NovaProjectPackageOutputDirectorySettingsTable -PackageSettings ([ordered]@{OutputDirectory = 'artifacts'})

        $result['Path'] | Should -Be 'artifacts'
    }
}
