function Resolve-NovaPackageUploadOutputFileSet {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package upload output file set is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OutputDirectory,
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$PackageType
    )

    $searchPattern = Get-NovaPackageArtifactSearchPattern -ProjectInfo $ProjectInfo -PackageType $PackageType
    $matchingFileList = @(
    Get-ChildItem -LiteralPath $OutputDirectory -File -ErrorAction Stop |
            Where-Object {$_.Name -like $searchPattern} |
            Sort-Object Name
    )

    if ($matchingFileList.Count -eq 0) {
        throw "Package file not found for package type '$PackageType' in '$OutputDirectory'. Expected pattern: $searchPattern. Run Merge-NovaModule first or provide -PackagePath."
    }

    return @(
    $matchingFileList | ForEach-Object {
        [pscustomobject]@{
            Type = $PackageType
            PackagePath = $_.FullName
            PackageFileName = $_.Name
        }
    }
    )
}
