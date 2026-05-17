BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadFileInfo.ps1')
}

Describe 'Get-NovaPackageUploadFileInfo' {
    It 'derives PackageFileName from the path when not provided' {
        $info = Get-NovaPackageUploadFileInfo -PackageType 'NuGet' -PackagePath '/o/x.nupkg'
        $info.PackageFileName | Should -Be 'x.nupkg'
        $info.Type | Should -Be 'NuGet'
        $info.PackagePath | Should -Be '/o/x.nupkg'
    }

    It 'uses the supplied PackageFileName when provided' {
        $info = Get-NovaPackageUploadFileInfo -PackageType 'Zip' -PackagePath '/o/x.zip' -PackageFileName 'alt.zip'
        $info.PackageFileName | Should -Be 'alt.zip'
    }
}
