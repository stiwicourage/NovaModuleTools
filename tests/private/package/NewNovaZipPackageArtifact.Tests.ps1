BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaZipPackageArtifact.ps1')

    function Get-NovaPackageContentItemList {param($ProjectInfo, $PackageMetadata) return @([pscustomobject]@{SourcePath='/dist/x/a.txt'; PackagePath='x/a.txt'})}
    function Invoke-NovaPackageArchiveCreation {param($PackagePath, $EntryWriter) $script:packagePath = $PackagePath}
    function Add-NovaZipFileEntry {param($Archive, $EntryPath, $SourcePath)}
}

Describe 'New-NovaZipPackageArtifact' {
    It 'invokes the archive creator with the metadata package path' {
        $project = [pscustomobject]@{OutputModuleDir='/dist/x'}
        $meta = [pscustomobject]@{PackagePath='/o/X.1.0.0.zip'}
        New-NovaZipPackageArtifact -ProjectInfo $project -PackageMetadata $meta
        $script:packagePath | Should -Be '/o/X.1.0.0.zip'
    }

    It 'writes one zip entry per content item' {
        $project = [pscustomobject]@{OutputModuleDir='/dist/x'}
        $meta = [pscustomobject]@{PackagePath='/o/X.1.0.0.zip'}
        $script:fileEntries = New-Object System.Collections.Generic.List[string]
        Mock Add-NovaZipFileEntry {param($Archive,$EntryPath,$SourcePath) $script:fileEntries.Add($EntryPath)}
        Mock Invoke-NovaPackageArchiveCreation {param($PackagePath, $EntryWriter) & $EntryWriter 'archive-stub'}
        New-NovaZipPackageArtifact -ProjectInfo $project -PackageMetadata $meta
        $script:fileEntries | Should -Contain 'x/a.txt'
    }
}
