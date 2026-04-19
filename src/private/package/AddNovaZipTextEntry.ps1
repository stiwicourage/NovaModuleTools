function Add-NovaZipTextEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.IO.Compression.ZipArchive]$Archive,
        [Parameter(Mandatory)][string]$EntryPath,
        [Parameter(Mandatory)][string]$Content
    )

    $entry = $Archive.CreateEntry($EntryPath, [System.IO.Compression.CompressionLevel]::Optimal)
    $streamWriter = [System.IO.StreamWriter]::new($entry.Open(),[System.Text.UTF8Encoding]::new($false))
    try {
        $streamWriter.Write($Content)
    }
    finally {
        $streamWriter.Dispose()
    }
}

