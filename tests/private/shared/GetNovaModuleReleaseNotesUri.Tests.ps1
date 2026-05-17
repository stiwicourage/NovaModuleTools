BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaModuleReleaseNotesUri.ps1')

    function Get-NovaModulePsDataValue {param([string]$Name, [object]$Module)}
}

Describe 'Get-NovaModuleReleaseNotesUri' {
    It 'returns the trimmed release notes URI from PSData' {
        Mock Get-NovaModulePsDataValue {return '  https://example/notes  '}

        Get-NovaModuleReleaseNotesUri -Module ([pscustomobject]@{}) | Should -Be 'https://example/notes'
    }

    It 'returns null when no release notes are configured' {
        Mock Get-NovaModulePsDataValue {return ''}

        Get-NovaModuleReleaseNotesUri -Module ([pscustomobject]@{}) | Should -BeNullOrEmpty
    }
}
