function Add-NovaZipFileEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.IO.Compression.ZipArchive]$Archive,
        [Parameter(Mandatory)][string]$EntryPath,
        [Parameter(Mandatory)][string]$SourcePath
    )

    $entry = $Archive.CreateEntry($EntryPath, [System.IO.Compression.CompressionLevel]::Optimal)
    $entryStream = $entry.Open()
    $sourceStream = [System.IO.File]::OpenRead($SourcePath)
    try {
        $sourceStream.CopyTo($entryStream)
    }
    finally {
        $sourceStream.Dispose()
        $entryStream.Dispose()
    }
}

