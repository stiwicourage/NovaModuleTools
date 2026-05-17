BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadTarget.ps1')

    function Get-NovaPackageRepository {param($ProjectInfo, $Repository) return [pscustomobject]@{Name='Nexus'; Url='repo'}}
    function Get-NovaPackageUploadTargetUrl {param($PackageSettings, $RepositorySettings, $Url) return 'resolved-url'}
    function Get-NovaPackageUploadPath {param($PackageSettings, $RepositorySettings, $UploadPath) return 'nuget'}
    function Get-NovaPackageUploadTargetSettingBundle {param($PackageSettings, $RepositorySettings)
        return [pscustomobject]@{Repository='Nexus'; Headers=@{H='1'}; Auth=$null}
    }
}

Describe 'Resolve-NovaPackageUploadTarget' {
    It 'composes the resolved upload target from its collaborators' {
        $project = [pscustomobject]@{Package=[pscustomobject]@{}}
        $target = Resolve-NovaPackageUploadTarget -ProjectInfo $project -Url 'x' -Repository 'Nexus' -UploadPath 'p'
        $target.Url | Should -Be 'resolved-url'
        $target.UploadPath | Should -Be 'nuget'
        $target.Repository | Should -Be 'Nexus'
        $target.Headers.H | Should -Be '1'
    }
}
