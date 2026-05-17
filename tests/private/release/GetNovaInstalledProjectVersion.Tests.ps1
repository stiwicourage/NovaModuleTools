BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaInstalledProjectVersion.ps1')

    function Get-NovaInstalledProjectManifestPath {param($ProjectInfo, $ModuleDirectoryPath) return '/nonexistent.psd1'}
    function Format-NovaCliVersionString {param($Name, $Version) return "$Name $Version"}
    function Get-NovaProjectInfo {return [pscustomobject]@{ProjectName='X'}}
    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
    function Test-ModuleManifest {param($Path, $ErrorAction) return [pscustomobject]@{Version=[version]'1.2.3'}}
}

Describe 'Get-NovaInstalledProjectVersion' {
    It 'throws when manifest does not exist' {
        Mock Get-NovaInstalledProjectManifestPath {return '/does/not/exist.psd1'}
        {Get-NovaInstalledProjectVersion -ProjectInfo ([pscustomobject]@{ProjectName='X'})} | Should -Throw '*Local module install not found*'
    }

    It 'returns formatted name+version when manifest exists' {
        $tmp = [System.IO.Path]::GetTempFileName()
        try {
            Mock Get-NovaInstalledProjectManifestPath {return $tmp}
            Mock Test-ModuleManifest {return [pscustomobject]@{Version=[version]'2.0.0'}}
            Get-NovaInstalledProjectVersion -ProjectInfo ([pscustomobject]@{ProjectName='X'}) | Should -Be 'X 2.0.0'
        } finally {
            Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
        }
    }

    It 'falls back to Get-NovaProjectInfo when -ProjectInfo is omitted' {
        $tmp = [System.IO.Path]::GetTempFileName()
        try {
            Mock Get-NovaInstalledProjectManifestPath {return $tmp}
            Mock Test-ModuleManifest {return [pscustomobject]@{Version=[version]'3.0.0'}}
            Mock Get-NovaProjectInfo {return [pscustomobject]@{ProjectName='Defaulted'}}
            Get-NovaInstalledProjectVersion | Should -Be 'Defaulted 3.0.0'
        } finally {
            Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
        }
    }
}
