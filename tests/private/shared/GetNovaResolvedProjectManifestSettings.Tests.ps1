BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaResolvedProjectManifestSettings.ps1')
}

Describe 'Get-NovaResolvedProjectManifestSettings' {
    It 'returns an empty ordered table when project data has no Manifest key' {
        $result = Get-NovaResolvedProjectManifestSettings -ProjectData @{}

        $result.Count | Should -Be 0
    }

    It 'returns a copy of the Manifest dictionary when present' {
        $manifest = [ordered]@{Author = 'me'; Version = '1.0.0'}

        $result = Get-NovaResolvedProjectManifestSettings -ProjectData @{Manifest = $manifest}

        $result.Author | Should -Be 'me'
        $result.Version | Should -Be '1.0.0'
    }

    It 'returns an empty table when Manifest is not a dictionary' {
        $result = Get-NovaResolvedProjectManifestSettings -ProjectData @{Manifest = 'wrong'}

        $result.Count | Should -Be 0
    }
}
