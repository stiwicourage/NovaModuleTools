function Get-NovaPackageContentItemList {param($ProjectInfo, $PackageMetadata) return @([pscustomobject]@{SourcePath='/dist/x/a.txt'; PackagePath='x/a.txt'})}
function Invoke-NovaPackageArchiveCreation {param($PackagePath, $EntryWriter) $script:packagePath = $PackagePath}
function Add-NovaZipFileEntry {param($Archive, $EntryPath, $SourcePath)}

function Get-NewNovaZipPackageArtifactScenario {
    return [pscustomobject]@{
        Project = [pscustomobject]@{OutputModuleDir = '/dist/x'}
        Metadata = [pscustomobject]@{PackagePath = '/o/X.1.0.0.zip'}
        FileEntries = New-Object System.Collections.Generic.List[string]
    }
}

function Set-NewNovaZipPackageArtifactWriterState {
    param($Scenario)

    $script:fileEntries = $Scenario.FileEntries
}

function Register-NewNovaZipPackageArtifactEntryMocks {
    Mock Add-NovaZipFileEntry {param($Archive,$EntryPath,$SourcePath) $script:fileEntries.Add($EntryPath)}
}

function Register-NewNovaZipPackageArtifactArchiveCreationMock {
    Mock Invoke-NovaPackageArchiveCreation {param($PackagePath, $EntryWriter) & $EntryWriter 'archive-stub'}
}

function Invoke-NewNovaZipPackageArtifactWriterScenario {
    $scenario = Get-NewNovaZipPackageArtifactScenario
    Set-NewNovaZipPackageArtifactWriterState -Scenario $scenario
    Register-NewNovaZipPackageArtifactEntryMocks
    Register-NewNovaZipPackageArtifactArchiveCreationMock
    New-NovaZipPackageArtifact -ProjectInfo $scenario.Project -PackageMetadata $scenario.Metadata
}
