function Assert-NovaPackageMetadata {param($PackageMetadata)}
function Initialize-NovaPackageOutputDirectory {param($ProjectInfo,$PackageMetadataList)}
function New-NovaPackageArtifact {param($ProjectInfo,$PackageMetadata,[switch]$OutputDirectoryReady) [pscustomobject]@{PackagePath=$PackageMetadata.PackagePath}}
