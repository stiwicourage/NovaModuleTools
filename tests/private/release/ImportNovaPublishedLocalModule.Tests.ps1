BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/ImportNovaPublishedLocalModule.ps1')

    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Import-NovaPublishedLocalModule' {
    It 'throws when the manifest path does not exist' {
        {Import-NovaPublishedLocalModule -ProjectName 'X' -ManifestPath '/does/not/exist.psd1'} | Should -Throw '*Expected locally published module manifest*'
    }

    It 'imports the module and removes stale loaded copies' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("NovaImportTest-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $manifestPath = Join-Path $tempDir 'NovaImportTestMod.psd1'
        $modulePath = Join-Path $tempDir 'NovaImportTestMod.psm1'
        Set-Content -LiteralPath $modulePath -Value 'function Test-NovaImportProbe {"ok"}'
        New-ModuleManifest -Path $manifestPath -RootModule 'NovaImportTestMod.psm1' -FunctionsToExport @('Test-NovaImportProbe') -ModuleVersion '1.0.0' -Author 'Test'
        try {
            $m = Import-NovaPublishedLocalModule -ProjectName 'NovaImportTestMod' -ManifestPath $manifestPath
            $m.Name | Should -Be 'NovaImportTestMod'
        } finally {
            Get-Module NovaImportTestMod | Remove-Module -Force -ErrorAction SilentlyContinue
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
