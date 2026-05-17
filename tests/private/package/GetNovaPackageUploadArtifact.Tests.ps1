BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadArtifact.ps1')

    function Join-NovaPackageUploadUrl {param($Url, $UploadPath, $PackageFileName) return "$Url/$UploadPath/$PackageFileName"}
}

Describe 'Get-NovaPackageUploadArtifact' {
    It 'projects the artifact with the joined upload URL' {
        $fileInfo = [pscustomobject]@{Type='NuGet'; PackagePath='/o/x.nupkg'; PackageFileName='x.nupkg'}
        $target = [pscustomobject]@{Repository='Nexus'; Url='https://x'; UploadPath='nuget'}
        $headers = @{H=1}
        $artifact = Get-NovaPackageUploadArtifact -PackageFileInfo $fileInfo -UploadTarget $target -UploadHeaders $headers
        $artifact.Type | Should -Be 'NuGet'
        $artifact.PackageFileName | Should -Be 'x.nupkg'
        $artifact.Repository | Should -Be 'Nexus'
        $artifact.Headers | Should -Be $headers
        $artifact.UploadUrl | Should -Be 'https://x/nuget/x.nupkg'
    }
}
