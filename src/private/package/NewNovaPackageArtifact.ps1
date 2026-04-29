function New-NovaPackageArtifact {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'New-NovaModulePackage performs the user-facing ShouldProcess confirmation before calling this internal helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata,
        [switch]$OutputDirectoryReady
    )

    Assert-NovaPackageMetadata -PackageMetadata $PackageMetadata
    if (-not $OutputDirectoryReady) {
        Initialize-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo -PackageMetadata $PackageMetadata
    }

    switch ($PackageMetadata.Type) {
        'NuGet' {
            New-NovaNuGetPackageArtifact -ProjectInfo $ProjectInfo -PackageMetadata $PackageMetadata
        }
        'Zip' {
            New-NovaZipPackageArtifact -ProjectInfo $ProjectInfo -PackageMetadata $PackageMetadata
        }
        default {
            Stop-NovaOperation -Message "Unsupported package type: $( $PackageMetadata.Type )" -ErrorId 'Nova.Validation.UnsupportedPackageArtifactType' -Category InvalidArgument -TargetObject $PackageMetadata.Type
        }
    }

    return [pscustomobject]@{
        Type = $PackageMetadata.Type
        Latest = [bool]$PackageMetadata.Latest
        Id = $PackageMetadata.Id
        Version = $PackageMetadata.Version
        PackageFileName = $PackageMetadata.PackageFileName
        PackagePath = $PackageMetadata.PackagePath
        OutputDirectory = $PackageMetadata.OutputDirectory
        SourceModuleDirectory = $ProjectInfo.OutputModuleDir
    }
}
