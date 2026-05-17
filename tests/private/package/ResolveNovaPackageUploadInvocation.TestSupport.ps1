function Get-NovaPackageUploadFileList {param($ProjectInfo, $PackagePath, $PackageType)
    return @([pscustomobject]@{Type='NuGet'; PackagePath='/o/x.nupkg'; PackageFileName='x.nupkg'})
}
function Resolve-NovaPackageUploadTarget {param($ProjectInfo, $Url, $Repository, $UploadPath)
    return [pscustomobject]@{Repository='Nexus'; Url='https://x'; UploadPath='nuget'; Headers=@{}; Auth=$null}
}
function Resolve-NovaPackageUploadHeaders {param($UploadTarget, $UploadOption) return @{H='1'}}
function Get-NovaPackageUploadArtifact {param($PackageFileInfo, $UploadTarget, $UploadHeaders)
    return [pscustomobject]@{PackageFileName=$PackageFileInfo.PackageFileName; UploadUrl='https://x/nuget/' + $PackageFileInfo.PackageFileName}
}
