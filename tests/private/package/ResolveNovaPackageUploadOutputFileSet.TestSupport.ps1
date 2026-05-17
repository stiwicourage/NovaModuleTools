function Get-NovaPackageArtifactSearchPattern {param($ProjectInfo, $PackageType) return '*.nupkg'}
function Get-NovaPackageUploadOutputDirectoryFileList {param($OutputDirectory, $SearchPattern, $PackageType)
    return @([pscustomobject]@{FullName='/o/x.nupkg'; Name='x.nupkg'})
}
function Get-NovaPackageUploadFileInfo {param($PackageType, $PackagePath, $PackageFileName)
    return [pscustomobject]@{Type=$PackageType; PackagePath=$PackagePath; PackageFileName=$PackageFileName}
}
