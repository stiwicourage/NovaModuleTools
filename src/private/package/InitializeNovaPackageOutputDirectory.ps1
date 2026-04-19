function Initialize-NovaPackageOutputDirectory {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Pack-NovaModule performs the user-facing ShouldProcess confirmation before calling this internal preparation helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata
    )

    if ($PackageMetadata.CleanOutputDirectory) {
        Clear-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo -OutputDirectory $PackageMetadata.OutputDirectory
    }

    if (-not (Test-Path -LiteralPath $PackageMetadata.OutputDirectory)) {
        $null = New-Item -ItemType Directory -Path $PackageMetadata.OutputDirectory -Force
    }
}

