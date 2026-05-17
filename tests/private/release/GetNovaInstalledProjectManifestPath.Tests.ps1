BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaInstalledProjectManifestPath.ps1')

    function Resolve-NovaLocalPublishPath {param($ModuleDirectoryPath) return '/m'}
    function Get-NovaPublishedLocalManifestPath {param($PublishInvocation) return $PublishInvocation}
    function Get-NovaProjectInfo {return [pscustomobject]@{ProjectName='X'}}
}

Describe 'Get-NovaInstalledProjectManifestPath' {
    It 'builds a local PublishInvocation and delegates to Get-NovaPublishedLocalManifestPath' {
        $project = [pscustomobject]@{ProjectName='Sample'}
        $invocation = Get-NovaInstalledProjectManifestPath -ProjectInfo $project -ModuleDirectoryPath '/m'
        $invocation.IsLocal | Should -BeTrue
        $invocation.Target | Should -Be '/m'
        $invocation.Parameters.ProjectInfo | Should -Be $project
    }
}
