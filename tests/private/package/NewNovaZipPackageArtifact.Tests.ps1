BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaZipPackageArtifact.ps1')

    . (Join-Path $PSScriptRoot 'NewNovaZipPackageArtifact.TestSupport.ps1')
}

Describe 'New-NovaZipPackageArtifact' {
    It 'invokes the archive creator with the metadata package path' {
        $project = [pscustomobject]@{OutputModuleDir='/dist/x'}
        $meta = [pscustomobject]@{PackagePath='/o/X.1.0.0.zip'}
        New-NovaZipPackageArtifact -ProjectInfo $project -PackageMetadata $meta
        $script:packagePath | Should -Be '/o/X.1.0.0.zip'
    }

    It 'writes one zip entry per content item' {
        Invoke-NewNovaZipPackageArtifactWriterScenario
        $script:fileEntries | Should -Contain 'x/a.txt'
    }
}
