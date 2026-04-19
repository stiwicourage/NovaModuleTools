function Invoke-NovaPackageArchiveCreation {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Merge-NovaModule performs the user-facing ShouldProcess confirmation before calling internal archive creation helpers.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PackagePath,
        [Parameter(Mandatory)][scriptblock]$EntryWriter
    )

    Remove-Item -LiteralPath $PackagePath -Force -ErrorAction SilentlyContinue
    $fileStream = [System.IO.File]::Open($PackagePath, [System.IO.FileMode]::CreateNew)
    $archive = [System.IO.Compression.ZipArchive]::new($fileStream, [System.IO.Compression.ZipArchiveMode]::Create, $false)
    try {
        & $EntryWriter $archive
    }
    finally {
        $archive.Dispose()
        $fileStream.Dispose()
    }
}
