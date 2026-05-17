function Get-NovaPackageRepository {param($ProjectInfo, $Repository) return [pscustomobject]@{Name='Nexus'; Url='repo'}}
function Get-NovaPackageUploadTargetUrl {param($PackageSettings, $RepositorySettings, $Url) return 'resolved-url'}
function Get-NovaPackageUploadPath {param($PackageSettings, $RepositorySettings, $UploadPath) return 'nuget'}
function Get-NovaPackageUploadTargetSettingBundle {param($PackageSettings, $RepositorySettings)
    return [pscustomobject]@{Repository='Nexus'; Headers=@{H='1'}; Auth=$null}
}
