BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaPackageArtifacts.ps1')
    function Assert-NovaPackageMetadata {param($PackageMetadata)}
    function Initialize-NovaPackageOutputDirectory {param($ProjectInfo,$PackageMetadataList)}
    function New-NovaPackageArtifact {param($ProjectInfo,$PackageMetadata,[switch]$OutputDirectoryReady) [pscustomobject]@{PackagePath=$PackageMetadata.PackagePath}}
}

Describe 'New-NovaPackageArtifacts' {
    It 'returns empty when no metadata provided' {
        $r = New-NovaPackageArtifacts -ProjectInfo ([pscustomobject]@{}) -PackageMetadataList @()
        @($r).Count | Should -Be 0
    }
    It 'asserts each metadata and creates one artifact per entry' {
        Mock Assert-NovaPackageMetadata {}
        Mock Initialize-NovaPackageOutputDirectory {}
        Mock New-NovaPackageArtifact {param($ProjectInfo,$PackageMetadata,[switch]$OutputDirectoryReady) [pscustomobject]@{PackagePath=$PackageMetadata.PackagePath}}
        $list = @(
            [pscustomobject]@{PackagePath='/a.nupkg'},
            [pscustomobject]@{PackagePath='/b.zip'}
        )
        $r = @(New-NovaPackageArtifacts -ProjectInfo ([pscustomobject]@{}) -PackageMetadataList $list)
        $r.Count | Should -Be 2
        Should -Invoke Assert-NovaPackageMetadata -Times 2
        Should -Invoke Initialize-NovaPackageOutputDirectory -Times 1
        Should -Invoke New-NovaPackageArtifact -Times 2
    }
}
