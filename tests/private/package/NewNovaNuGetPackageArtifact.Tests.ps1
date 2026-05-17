BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaNuGetPackageArtifact.ps1')

    . (Join-Path $PSScriptRoot 'NewNovaNuGetPackageArtifact.TestSupport.ps1')
}

Describe 'New-NovaNuGetPackageArtifact' {
    It 'invokes the archive creator with the metadata package path' {
        $project = [pscustomobject]@{OutputModuleDir='/dist/x'}
        $meta = [pscustomobject]@{Id='X'; PackagePath='/o/X.1.0.0.nupkg'}
        New-NovaNuGetPackageArtifact -ProjectInfo $project -PackageMetadata $meta
        $script:packagePath | Should -Be '/o/X.1.0.0.nupkg'
    }

    It 'writes the expected zip entries when the writer is invoked' {
        Invoke-NewNovaNuGetPackageArtifactWriterScenario
        $script:textEntries | Should -Contain '_rels/.rels'
        $script:textEntries | Should -Contain 'X.nuspec'
        $script:textEntries | Should -Contain '[Content_Types].xml'
        $script:fileEntries | Should -Contain 'content/x/a.txt'
    }
}
