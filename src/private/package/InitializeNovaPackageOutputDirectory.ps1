function Initialize-NovaPackageOutputDirectory {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'New-NovaModulePackage performs the user-facing ShouldProcess confirmation before calling this internal preparation helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [AllowEmptyCollection()][Alias('PackageMetadata')][Parameter(Mandatory)][object[]]$PackageMetadataList
    )

    $packageMetadata = @($PackageMetadataList) | Select-Object -First 1
    if ($null -eq $packageMetadata) {
        Stop-NovaOperation -Message 'Package metadata list cannot be empty.' -ErrorId 'Nova.Validation.PackageMetadataListEmpty' -Category InvalidArgument -TargetObject 'PackageMetadataList'
    }

    if ($packageMetadata.CleanOutputDirectory) {
        Clear-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo -OutputDirectory $packageMetadata.OutputDirectory
    }

    if (-not (Test-Path -LiteralPath $packageMetadata.OutputDirectory)) {
        $null = New-Item -ItemType Directory -Path $packageMetadata.OutputDirectory -Force
    }
}
