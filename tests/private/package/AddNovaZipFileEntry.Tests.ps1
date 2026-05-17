BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/AddNovaZipFileEntry.ps1')
}

Describe 'Add-NovaZipFileEntry' {
    It 'copies file content into the zip entry path' {
        $zipPath = Join-Path ([System.IO.Path]::GetTempPath()) ("nova-{0}.zip" -f [guid]::NewGuid())
        $sourcePath = Join-Path ([System.IO.Path]::GetTempPath()) ("nova-{0}.txt" -f [guid]::NewGuid())
        Set-Content -LiteralPath $sourcePath -Value 'hello' -NoNewline
        try {
            $fs = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
            $archive = [System.IO.Compression.ZipArchive]::new($fs, [System.IO.Compression.ZipArchiveMode]::Create, $false)
            try {
                Add-NovaZipFileEntry -Archive $archive -EntryPath 'a/b.txt' -SourcePath $sourcePath
            } finally {
                $archive.Dispose(); $fs.Dispose()
            }
            $archive2 = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
            try {
                $entry = $archive2.GetEntry('a/b.txt')
                $entry | Should -Not -BeNullOrEmpty
                $reader = [System.IO.StreamReader]::new($entry.Open())
                try {$reader.ReadToEnd() | Should -Be 'hello'} finally {$reader.Dispose()}
            } finally {$archive2.Dispose()}
        } finally {
            Remove-Item -LiteralPath $zipPath -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $sourcePath -ErrorAction SilentlyContinue
        }
    }
}
