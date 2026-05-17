BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/AddNovaZipTextEntry.ps1')
}

Describe 'Add-NovaZipTextEntry' {
    It 'writes UTF-8 text without BOM into the zip entry' {
        $zipPath = Join-Path ([System.IO.Path]::GetTempPath()) ("nova-{0}.zip" -f [guid]::NewGuid())
        try {
            $fs = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
            $archive = [System.IO.Compression.ZipArchive]::new($fs, [System.IO.Compression.ZipArchiveMode]::Create, $false)
            try {Add-NovaZipTextEntry -Archive $archive -EntryPath 'note.txt' -Content 'hello'} finally {$archive.Dispose(); $fs.Dispose()}
            $archive2 = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
            try {
                $reader = [System.IO.StreamReader]::new($archive2.GetEntry('note.txt').Open())
                try {$reader.ReadToEnd() | Should -Be 'hello'} finally {$reader.Dispose()}
            } finally {$archive2.Dispose()}
        } finally {Remove-Item -LiteralPath $zipPath -ErrorAction SilentlyContinue}
    }
}
