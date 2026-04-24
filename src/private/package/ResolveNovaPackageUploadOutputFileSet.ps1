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
        Stop-NovaOperation -Message "Package file not found for package type '$PackageType' in '$OutputDirectory'. Expected pattern: $searchPattern. Run New-NovaModulePackage first or provide -PackagePath." -ErrorId 'Nova.Workflow.PackageOutputArtifactNotFound' -Category InvalidOperation -TargetObject $PackageType
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
