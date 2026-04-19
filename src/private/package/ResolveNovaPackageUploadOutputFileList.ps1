function Resolve-NovaPackageUploadOutputFileList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package upload output file list is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [string[]]$PackageType
    )

    $outputDirectory = Get-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo
    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        throw "Package output directory not found: $outputDirectory. Run Merge-NovaModule first or provide -PackagePath."
    }

    return @(
    @(Resolve-NovaPackageUploadTypeList -ProjectInfo $ProjectInfo -PackageType $PackageType) |
            ForEach-Object {
                Resolve-NovaPackageUploadOutputFileSet -OutputDirectory $outputDirectory -ProjectInfo $ProjectInfo -PackageType $_
            }
    )
}
