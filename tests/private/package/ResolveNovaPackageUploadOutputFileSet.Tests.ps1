BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadOutputFileSet.ps1')

    function Get-NovaPackageArtifactSearchPattern {param($ProjectInfo, $PackageType) return '*.nupkg'}
    function Get-NovaPackageUploadOutputDirectoryFileList {param($OutputDirectory, $SearchPattern, $PackageType)
        return @([pscustomobject]@{FullName='/o/x.nupkg'; Name='x.nupkg'})
    }
    function Get-NovaPackageUploadFileInfo {param($PackageType, $PackagePath, $PackageFileName)
        return [pscustomobject]@{Type=$PackageType; PackagePath=$PackagePath; PackageFileName=$PackageFileName}
    }
}

Describe 'Resolve-NovaPackageUploadOutputFileSet' {
    It 'returns upload file info entries for each matching file' {
        $set = Resolve-NovaPackageUploadOutputFileSet -OutputDirectory '/o' -ProjectInfo ([pscustomobject]@{}) -PackageType 'NuGet'
        @($set).Count | Should -Be 1
        $set[0].PackagePath | Should -Be '/o/x.nupkg'
        $set[0].PackageFileName | Should -Be 'x.nupkg'
    }
}
