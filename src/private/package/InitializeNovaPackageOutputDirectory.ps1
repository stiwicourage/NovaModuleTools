function Initialize-NovaPackageOutputDirectory {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'New-NovaModulePackage performs the user-facing ShouldProcess confirmation before calling this internal preparation helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Alias('PackageMetadata')][Parameter(Mandatory)][object[]]$PackageMetadataList
    )

    $packageMetadata = @($PackageMetadataList)[0]
    if ($null -eq $packageMetadata) {
        Stop-NovaOperation -Message 'Package metadata list cannot be empty.' -ErrorId 'Nova.Validation.PackageMetadataListEmpty' -Category InvalidArgument -TargetObject 'PackageMetadataList'
    }

    if ($PackageMetadata.CleanOutputDirectory) {
        Clear-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo -OutputDirectory $PackageMetadata.OutputDirectory
    }

    if (-not (Test-Path -LiteralPath $PackageMetadata.OutputDirectory)) {
        $null = New-Item -ItemType Directory -Path $PackageMetadata.OutputDirectory -Force
    }
}
