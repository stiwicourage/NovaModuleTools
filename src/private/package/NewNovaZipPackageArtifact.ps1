function New-NovaZipPackageArtifact {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Merge-NovaModule performs the user-facing ShouldProcess confirmation before calling this internal writer.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata
    )

    $fileEntries = Get-NovaPackageContentItemList -ProjectInfo $ProjectInfo -PackageMetadata $PackageMetadata
    Invoke-NovaPackageArchiveCreation -PackagePath $PackageMetadata.PackagePath -EntryWriter {
        param($Archive)

        foreach ($fileEntry in $fileEntries) {
            Add-NovaZipFileEntry -Archive $Archive -EntryPath $fileEntry.PackagePath -SourcePath $fileEntry.SourcePath
        }
    }
}
