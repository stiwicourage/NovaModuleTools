BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadWorkflowOperation.ps1')
}

Describe 'Get-NovaPackageUploadWorkflowOperation' {
    It 'describes a single artifact by name' {
        $list = @([pscustomobject]@{Type='NuGet'; PackageFileName='x.nupkg'})
        Get-NovaPackageUploadWorkflowOperation -UploadArtifactList $list | Should -Be 'Upload NuGet package artifact x.nupkg'
    }

    It 'describes the count for multiple artifacts' {
        $list = @([pscustomobject]@{Type='NuGet'; PackageFileName='a.nupkg'}, [pscustomobject]@{Type='Zip'; PackageFileName='b.zip'})
        Get-NovaPackageUploadWorkflowOperation -UploadArtifactList $list | Should -Be 'Upload 2 package artifacts'
    }
}
