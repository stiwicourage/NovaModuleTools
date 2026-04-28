function New-NovaPackageArtifacts {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'New-NovaModulePackage performs the user-facing ShouldProcess confirmation before calling this internal helper.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package artifacts is the established domain term for the requested collection.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$PackageMetadataList
    )

    $resolvedPackageMetadataList = @($PackageMetadataList)
    if ($resolvedPackageMetadataList.Count -eq 0) {
        return @()
    }

    foreach ($packageMetadata in $resolvedPackageMetadataList) {
        Assert-NovaPackageMetadata -PackageMetadata $packageMetadata
    }

    Initialize-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo -PackageMetadataList $resolvedPackageMetadataList
    return @(
    $resolvedPackageMetadataList | ForEach-Object {
        New-NovaPackageArtifact -ProjectInfo $ProjectInfo -PackageMetadata $_ -OutputDirectoryReady
    }
    )
}
