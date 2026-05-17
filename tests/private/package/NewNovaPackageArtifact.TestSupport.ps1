function Assert-NovaPackageMetadata {param($PackageMetadata)}
function Initialize-NovaPackageOutputDirectory {param($ProjectInfo, $PackageMetadata)}
function New-NovaNuGetPackageArtifact {param($ProjectInfo, $PackageMetadata) $script:nugetCalled = $true}
function New-NovaZipPackageArtifact {param($ProjectInfo, $PackageMetadata) $script:zipCalled = $true}
function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
