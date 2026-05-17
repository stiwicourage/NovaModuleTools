BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaModulePsDataValue.ps1')
}

Describe 'Get-NovaModulePsDataValue' {
    It 'returns the value from a hashtable PSData' {
        $module = [pscustomobject]@{PrivateData = @{PSData = @{ReleaseNotes = 'rn'}}}

        Get-NovaModulePsDataValue -Name 'ReleaseNotes' -Module $module | Should -Be 'rn'
    }

    It 'returns the value from a PSCustomObject PSData' {
        $module = [pscustomobject]@{PrivateData = [pscustomobject]@{PSData = [pscustomobject]@{ReleaseNotes = 'rn'}}}

        Get-NovaModulePsDataValue -Name 'ReleaseNotes' -Module $module | Should -Be 'rn'
    }

    It 'returns null when PSData is missing the named entry' {
        $module = [pscustomobject]@{PrivateData = [pscustomobject]@{PSData = [pscustomobject]@{Other = 'x'}}}

        Get-NovaModulePsDataValue -Name 'ReleaseNotes' -Module $module | Should -BeNullOrEmpty
    }

    It 'returns null when PSData itself is null' {
        $module = [pscustomobject]@{PrivateData = [pscustomobject]@{PSData = $null}}

        Get-NovaModulePsDataValue -Name 'ReleaseNotes' -Module $module | Should -BeNullOrEmpty
    }
}
