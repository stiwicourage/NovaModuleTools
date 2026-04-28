function Resolve-NovaPackageUploadOutputFileSet {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package upload output file set is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OutputDirectory,
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$PackageType
    )

    $searchPattern = Get-NovaPackageArtifactSearchPattern -ProjectInfo $ProjectInfo -PackageType $PackageType
    $matchingFileList = @(Get-NovaPackageUploadOutputDirectoryFileList -OutputDirectory $OutputDirectory -SearchPattern $searchPattern -PackageType $PackageType)

    return @(
    $matchingFileList | ForEach-Object {
        Get-NovaPackageUploadFileInfo -PackageType $PackageType -PackagePath $_.FullName -PackageFileName $_.Name
    }
    )
}
