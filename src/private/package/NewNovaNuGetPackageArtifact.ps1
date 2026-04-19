function New-NovaNuGetPackageArtifact {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Merge-NovaModule performs the user-facing ShouldProcess confirmation before calling this internal writer.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata
    )

    $fileEntries = Get-NovaPackageContentItemList -ProjectInfo $ProjectInfo -PackageMetadata $PackageMetadata
    $corePropertiesPath = "package/services/metadata/core-properties/$([System.Guid]::NewGuid().ToString('N') ).psmdcp"
    $nuspecFileName = "$( $PackageMetadata.Id ).nuspec"

    Invoke-NovaPackageArchiveCreation -PackagePath $PackageMetadata.PackagePath -EntryWriter {
        param($Archive)

        Add-NovaZipTextEntry -Archive $Archive -EntryPath '_rels/.rels' -Content (New-NovaPackageRelationshipsXml -NuspecFileName $nuspecFileName -CorePropertiesPath $corePropertiesPath)
        Add-NovaZipTextEntry -Archive $Archive -EntryPath $nuspecFileName -Content (New-NovaPackageNuspecXml -PackageMetadata $PackageMetadata)
        Add-NovaZipTextEntry -Archive $Archive -EntryPath '[Content_Types].xml' -Content (New-NovaPackageContentTypesXml -FileEntries $fileEntries)
        Add-NovaZipTextEntry -Archive $Archive -EntryPath $corePropertiesPath -Content (New-NovaPackageCorePropertiesXml -PackageMetadata $PackageMetadata)
        foreach ($fileEntry in $fileEntries) {
            Add-NovaZipFileEntry -Archive $Archive -EntryPath $fileEntry.PackagePath -SourcePath $fileEntry.SourcePath
        }
    }
}
