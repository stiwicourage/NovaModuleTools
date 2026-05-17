BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaNuGetPackageArtifact.ps1')

    function Get-NovaPackageContentItemList {param($ProjectInfo, $PackageMetadata) return @([pscustomobject]@{SourcePath='/dist/x/a.txt'; PackagePath='content/x/a.txt'})}
    function Invoke-NovaPackageArchiveCreation {param($PackagePath, $EntryWriter) $script:packagePath = $PackagePath; $script:writer = $EntryWriter}
    function New-NovaPackageRelationshipsXml {param($NuspecFileName, $CorePropertiesPath) return '<rels/>'}
    function New-NovaPackageNuspecXml {param($PackageMetadata) return '<nuspec/>'}
    function New-NovaPackageContentTypesXml {param($FileEntries) return '<types/>'}
    function New-NovaPackageCorePropertiesXml {param($PackageMetadata) return '<core/>'}
    function Add-NovaZipTextEntry {param($Archive, $EntryPath, $Content)}
    function Add-NovaZipFileEntry {param($Archive, $EntryPath, $SourcePath)}
}

Describe 'New-NovaNuGetPackageArtifact' {
    It 'invokes the archive creator with the metadata package path' {
        $project = [pscustomobject]@{OutputModuleDir='/dist/x'}
        $meta = [pscustomobject]@{Id='X'; PackagePath='/o/X.1.0.0.nupkg'}
        New-NovaNuGetPackageArtifact -ProjectInfo $project -PackageMetadata $meta
        $script:packagePath | Should -Be '/o/X.1.0.0.nupkg'
    }

    It 'writes the expected zip entries when the writer is invoked' {
        $project = [pscustomobject]@{OutputModuleDir='/dist/x'}
        $meta = [pscustomobject]@{Id='X'; PackagePath='/o/X.1.0.0.nupkg'}
        $script:textEntries = New-Object System.Collections.Generic.List[string]
        $script:fileEntries = New-Object System.Collections.Generic.List[string]
        Mock Add-NovaZipTextEntry {param($Archive,$EntryPath,$Content) $script:textEntries.Add($EntryPath)}
        Mock Add-NovaZipFileEntry {param($Archive,$EntryPath,$SourcePath) $script:fileEntries.Add($EntryPath)}
        Mock Invoke-NovaPackageArchiveCreation {param($PackagePath, $EntryWriter) & $EntryWriter 'archive-stub'}
        New-NovaNuGetPackageArtifact -ProjectInfo $project -PackageMetadata $meta
        $script:textEntries | Should -Contain '_rels/.rels'
        $script:textEntries | Should -Contain 'X.nuspec'
        $script:textEntries | Should -Contain '[Content_Types].xml'
        $script:fileEntries | Should -Contain 'content/x/a.txt'
    }
}
