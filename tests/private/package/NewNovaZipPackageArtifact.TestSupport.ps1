function Get-NovaPackageContentItemList {param($ProjectInfo, $PackageMetadata) return @([pscustomobject]@{SourcePath='/dist/x/a.txt'; PackagePath='x/a.txt'})}
function Invoke-NovaPackageArchiveCreation {param($PackagePath, $EntryWriter) $script:packagePath = $PackagePath}
function Add-NovaZipFileEntry {param($Archive, $EntryPath, $SourcePath)}
function Invoke-NewNovaZipPackageArtifactWriterScenario {
    $project = [pscustomobject]@{OutputModuleDir='/dist/x'}
    $meta = [pscustomobject]@{PackagePath='/o/X.1.0.0.zip'}
    $script:fileEntries = New-Object System.Collections.Generic.List[string]
    Mock Add-NovaZipFileEntry {param($Archive,$EntryPath,$SourcePath) $script:fileEntries.Add($EntryPath)}
    Mock Invoke-NovaPackageArchiveCreation {param($PackagePath, $EntryWriter) & $EntryWriter 'archive-stub'}
    New-NovaZipPackageArtifact -ProjectInfo $project -PackageMetadata $meta
}
