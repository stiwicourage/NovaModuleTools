BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadOutputFileSet.ps1')

    . (Join-Path $PSScriptRoot 'ResolveNovaPackageUploadOutputFileSet.TestSupport.ps1')
}

Describe 'Resolve-NovaPackageUploadOutputFileSet' {
    It 'returns upload file info entries for each matching file' {
        $set = Resolve-NovaPackageUploadOutputFileSet -OutputDirectory '/o' -ProjectInfo ([pscustomobject]@{}) -PackageType 'NuGet'
        @($set).Count | Should -Be 1
        $set[0].PackagePath | Should -Be '/o/x.nupkg'
        $set[0].PackageFileName | Should -Be 'x.nupkg'
    }
}
