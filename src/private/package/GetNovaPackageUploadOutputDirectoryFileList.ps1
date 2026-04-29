function Get-NovaPackageUploadOutputDirectoryFileList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package upload output directory file list is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OutputDirectory,
        [Parameter(Mandatory)][string]$SearchPattern,
        [Parameter(Mandatory)][string]$PackageType
    )

    $matchingFileList = @(
    Get-ChildItem -LiteralPath $OutputDirectory -File -ErrorAction Stop |
            Where-Object {$_.Name -like $SearchPattern} |
            Sort-Object Name
    )

    if ($matchingFileList.Count -eq 0) {
        Stop-NovaOperation -Message "Package file not found for package type '$PackageType' in '$OutputDirectory'. Expected pattern: $SearchPattern. Run New-NovaModulePackage first or provide -PackagePath." -ErrorId 'Nova.Workflow.PackageOutputArtifactNotFound' -Category InvalidOperation -TargetObject $PackageType
    }

    return $matchingFileList
}
