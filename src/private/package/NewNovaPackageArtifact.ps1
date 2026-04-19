function New-NovaPackageArtifact {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Pack-NovaModule performs the user-facing ShouldProcess confirmation before calling this internal helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata
    )

    Assert-NovaPackageMetadata -PackageMetadata $PackageMetadata
    $fileEntries = Get-NovaPackageContentItemList -ProjectInfo $ProjectInfo -PackageMetadata $PackageMetadata
    $corePropertiesPath = "package/services/metadata/core-properties/$([System.Guid]::NewGuid().ToString('N') ).psmdcp"
    $nuspecFileName = "$( $PackageMetadata.Id ).nuspec"

    Initialize-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo -PackageMetadata $PackageMetadata

    Remove-Item -LiteralPath $PackageMetadata.PackagePath -Force -ErrorAction SilentlyContinue
    $fileStream = [System.IO.File]::Open($PackageMetadata.PackagePath, [System.IO.FileMode]::CreateNew)
    $archive = [System.IO.Compression.ZipArchive]::new($fileStream, [System.IO.Compression.ZipArchiveMode]::Create, $false)
    try {
        Add-NovaZipTextEntry -Archive $archive -EntryPath '_rels/.rels' -Content (New-NovaPackageRelationshipsXml -NuspecFileName $nuspecFileName -CorePropertiesPath $corePropertiesPath)
        Add-NovaZipTextEntry -Archive $archive -EntryPath $nuspecFileName -Content (New-NovaPackageNuspecXml -PackageMetadata $PackageMetadata)
        Add-NovaZipTextEntry -Archive $archive -EntryPath '[Content_Types].xml' -Content (New-NovaPackageContentTypesXml -FileEntries $fileEntries)
        Add-NovaZipTextEntry -Archive $archive -EntryPath $corePropertiesPath -Content (New-NovaPackageCorePropertiesXml -PackageMetadata $PackageMetadata)
        foreach ($fileEntry in $fileEntries) {
            Add-NovaZipFileEntry -Archive $archive -EntryPath $fileEntry.PackagePath -SourcePath $fileEntry.SourcePath
        }
    }
    finally {
        $archive.Dispose()
        $fileStream.Dispose()
    }

    return [pscustomobject]@{
        Id = $PackageMetadata.Id
        Version = $PackageMetadata.Version
        PackageFileName = $PackageMetadata.PackageFileName
        PackagePath = $PackageMetadata.PackagePath
        OutputDirectory = $PackageMetadata.OutputDirectory
        SourceModuleDirectory = $ProjectInfo.OutputModuleDir
    }
}

