function Get-NovaPackageContentItemList {param($ProjectInfo, $PackageMetadata) return @([pscustomobject]@{SourcePath='/dist/x/a.txt'; PackagePath='content/x/a.txt'})}
function Invoke-NovaPackageArchiveCreation {param($PackagePath, $EntryWriter) $script:packagePath = $PackagePath; $script:writer = $EntryWriter}
function New-NovaPackageRelationshipsXml {param($NuspecFileName, $CorePropertiesPath) return '<rels/>'}
function New-NovaPackageNuspecXml {param($PackageMetadata) return '<nuspec/>'}
function New-NovaPackageContentTypesXml {param($FileEntries) return '<types/>'}
function New-NovaPackageCorePropertiesXml {param($PackageMetadata) return '<core/>'}
function Add-NovaZipTextEntry {param($Archive, $EntryPath, $Content)}
function Add-NovaZipFileEntry {param($Archive, $EntryPath, $SourcePath)}

function Get-NewNovaNuGetPackageArtifactScenario {
    return [pscustomobject]@{
        Project = [pscustomobject]@{OutputModuleDir = '/dist/x'}
        Metadata = [pscustomobject]@{Id = 'X'; PackagePath = '/o/X.1.0.0.nupkg'}
        TextEntries = New-Object System.Collections.Generic.List[string]
        FileEntries = New-Object System.Collections.Generic.List[string]
    }
}

function Set-NewNovaNuGetPackageArtifactWriterState {
    param($Scenario)

    $script:textEntries = $Scenario.TextEntries
    $script:fileEntries = $Scenario.FileEntries
}

function Register-NewNovaNuGetPackageArtifactTextEntryMock {
    Mock Add-NovaZipTextEntry {param($Archive,$EntryPath,$Content) $script:textEntries.Add($EntryPath)}
}

function Register-NewNovaNuGetPackageArtifactFileEntryMock {
    Mock Add-NovaZipFileEntry {param($Archive,$EntryPath,$SourcePath) $script:fileEntries.Add($EntryPath)}
}

function Register-NewNovaNuGetPackageArtifactArchiveCreationMock {
    Mock Invoke-NovaPackageArchiveCreation {param($PackagePath, $EntryWriter) & $EntryWriter 'archive-stub'}
}

function Invoke-NewNovaNuGetPackageArtifactWriterScenario {
    $scenario = Get-NewNovaNuGetPackageArtifactScenario
    Set-NewNovaNuGetPackageArtifactWriterState -Scenario $scenario
    Register-NewNovaNuGetPackageArtifactTextEntryMock
    Register-NewNovaNuGetPackageArtifactFileEntryMock
    Register-NewNovaNuGetPackageArtifactArchiveCreationMock
    New-NovaNuGetPackageArtifact -ProjectInfo $scenario.Project -PackageMetadata $scenario.Metadata
}
