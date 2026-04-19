function Initialize-NovaPackageOutputDirectory {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'New-NovaModulePackage performs the user-facing ShouldProcess confirmation before calling this internal preparation helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Alias('PackageMetadata')][Parameter(Mandatory)][object[]]$PackageMetadataList
    )

    $packageMetadata = @($PackageMetadataList)[0]
    if ($null -eq $packageMetadata) {
        throw 'Package metadata list cannot be empty.'
    }

    if ($PackageMetadata.CleanOutputDirectory) {
        Clear-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo -OutputDirectory $PackageMetadata.OutputDirectory
    }

    if (-not (Test-Path -LiteralPath $PackageMetadata.OutputDirectory)) {
        $null = New-Item -ItemType Directory -Path $PackageMetadata.OutputDirectory -Force
    }
}
