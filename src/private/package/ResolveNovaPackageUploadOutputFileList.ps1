function Resolve-NovaPackageUploadOutputFileList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package upload output file list is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [string[]]$PackageType
    )

    $resolvedTypeList = @(Resolve-NovaPackageUploadTypeList -ProjectInfo $ProjectInfo -PackageType $PackageType)
    $outputDirectory = Get-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo
    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        Stop-NovaOperation -Message "Package output directory not found: $outputDirectory. Run New-NovaModulePackage first or provide -PackagePath." -ErrorId 'Nova.Environment.PackageOutputDirectoryNotFound' -Category ObjectNotFound -TargetObject $outputDirectory
    }

    return @(
    $resolvedTypeList |
            ForEach-Object {
                Resolve-NovaPackageUploadOutputFileSet -OutputDirectory $outputDirectory -ProjectInfo $ProjectInfo -PackageType $_
            }
    )
}
