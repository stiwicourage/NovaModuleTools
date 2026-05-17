BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/ResolveNovaLocalPublishPath.ps1')

    function Get-LocalModulePath {return '/resolved/local/modules'}
}

Describe 'Resolve-NovaLocalPublishPath' {
    It 'returns the provided directory path when set' {
        Resolve-NovaLocalPublishPath -ModuleDirectoryPath '/custom' | Should -Be '/custom'
    }

    It 'falls back to Get-LocalModulePath when the path is empty' {
        Resolve-NovaLocalPublishPath -ModuleDirectoryPath '' | Should -Be '/resolved/local/modules'
    }

    It 'falls back to Get-LocalModulePath when whitespace only' {
        Resolve-NovaLocalPublishPath -ModuleDirectoryPath '   ' | Should -Be '/resolved/local/modules'
    }
}
