BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/InvokeNovaPackageArchiveCreation.ps1')
}

Describe 'Invoke-NovaPackageArchiveCreation' {
    It 'creates a zip archive and invokes the entry writer with the open archive' {
        $zipPath = Join-Path ([System.IO.Path]::GetTempPath()) ("nova-{0}.zip" -f [guid]::NewGuid())
        try {
            $writerCalled = $false
            Invoke-NovaPackageArchiveCreation -PackagePath $zipPath -EntryWriter {
                param($archive)
                $script:writerCalled = $true
                $archive | Should -BeOfType [System.IO.Compression.ZipArchive]
            }.GetNewClosure()
            Test-Path -LiteralPath $zipPath | Should -BeTrue
        } finally {Remove-Item -LiteralPath $zipPath -ErrorAction SilentlyContinue}
    }

    It 'overwrites an existing file before creating the archive' {
        $zipPath = Join-Path ([System.IO.Path]::GetTempPath()) ("nova-{0}.zip" -f [guid]::NewGuid())
        Set-Content -LiteralPath $zipPath -Value 'stale'
        try {
            Invoke-NovaPackageArchiveCreation -PackagePath $zipPath -EntryWriter {param($a)}
            (Get-Item -LiteralPath $zipPath).Length | Should -BeGreaterThan 0
        } finally {Remove-Item -LiteralPath $zipPath -ErrorAction SilentlyContinue}
    }
}
