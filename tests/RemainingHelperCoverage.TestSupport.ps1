function Assert-TestNovaPackageArtifactContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PackagePath
    )

    $archive = [System.IO.Compression.ZipFile]::OpenRead($PackagePath)
    try {
        $entryNames = @($archive.Entries | ForEach-Object FullName)
        $entryNames | Should -Contain '_rels/.rels'
        $entryNames | Should -Contain '[Content_Types].xml'
        $entryNames | Should -Contain 'PackageProject.nuspec'
        $entryNames | Should -Contain 'content/PackageProject/PackageProject.psd1'
        $entryNames | Should -Contain 'content/PackageProject/PackageProject.psm1'
        $entryNames | Should -Contain 'content/PackageProject/resources/nova'
        @($entryNames | Where-Object {$_ -like 'package/services/metadata/core-properties/*.psmdcp'}).Count | Should -Be 1

        $nuspecText = [System.IO.StreamReader]::new(($archive.GetEntry('PackageProject.nuspec')).Open()).ReadToEnd()
        $contentTypesText = [System.IO.StreamReader]::new(($archive.GetEntry('[Content_Types].xml')).Open()).ReadToEnd()
        $relsText = [System.IO.StreamReader]::new(($archive.GetEntry('_rels/.rels')).Open()).ReadToEnd()

        $nuspecText | Should -Match '<id>PackageProject</id>'
        $nuspecText | Should -Match '<version>2.3.4</version>'
        $nuspecText | Should -Match '<authors>Author One, Author Two</authors>'
        $nuspecText | Should -Match '<projectUrl>https://example.test/project</projectUrl>'
        $nuspecText | Should -Match '<releaseNotes>https://example.test/release-notes</releaseNotes>'
        $nuspecText | Should -Match '<licenseUrl>https://example.test/license</licenseUrl>'
        $contentTypesText | Should -Match 'Extension="nuspec"'
        $contentTypesText | Should -Match 'Extension="psd1"'
        $contentTypesText | Should -Match 'Extension="psm1"'
        $contentTypesText | Should -Match 'PartName="/content/PackageProject/resources/nova"'
        $relsText | Should -Match 'http://schemas.microsoft.com/packaging/2010/07/manifest'
        $relsText | Should -Match 'Target="/PackageProject.nuspec"'
    }
    finally {
        $archive.Dispose()
    }
}

function Assert-TestNovaZipPackageArtifactContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PackagePath
    )

    $archive = [System.IO.Compression.ZipFile]::OpenRead($PackagePath)
    try {
        $entryNames = @($archive.Entries | ForEach-Object FullName)
        $entryNames | Should -Contain 'PackageProject/PackageProject.psd1'
        $entryNames | Should -Contain 'PackageProject/PackageProject.psm1'
        $entryNames | Should -Contain 'PackageProject/resources/nova'
        $entryNames | Should -Not -Contain 'PackageProject.nuspec'
        $entryNames | Should -Not -Contain '_rels/.rels'
        $entryNames | Should -Not -Contain '[Content_Types].xml'
    }
    finally {
        $archive.Dispose()
    }
}

function Initialize-TestNovaPackageProjectLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $outputModuleDir = Join-Path $ProjectRoot 'dist/PackageProject'
    $packageOutputDir = Join-Path $ProjectRoot 'artifacts/packages'
    $resourceDir = Join-Path $outputModuleDir 'resources'
    New-Item -ItemType Directory -Path $resourceDir -Force | Out-Null
    '@{}' | Set-Content -LiteralPath (Join-Path $outputModuleDir 'PackageProject.psd1') -Encoding utf8
    'function Get-TestPackage { }' | Set-Content -LiteralPath (Join-Path $outputModuleDir 'PackageProject.psm1') -Encoding utf8
    '#!/usr/bin/env pwsh' | Set-Content -LiteralPath (Join-Path $resourceDir 'nova') -Encoding utf8

    return [pscustomobject]@{
        ProjectRoot = $ProjectRoot
        OutputModuleDir = $outputModuleDir
        PackageOutputDir = $packageOutputDir
    }
}

function Get-TestNovaPackageProjectInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Layout,
        [Parameter(Mandatory)][bool]$CleanOutputDirectory,
        [string[]]$PackageTypes = @('NuGet'),
        [bool]$Latest = $false,
        [string]$PackageFileName = 'PackageProject.2.3.4.nupkg',
        [bool]$AddVersionToFileName = $false,
        [switch]$OmitOptionalManifestMetadata
    )

    $manifest = [ordered]@{
        Author = 'Author One'
        Tags = @('Nova', 'Packaging')
        ProjectUri = 'https://example.test/project'
        ReleaseNotes = 'https://example.test/release-notes'
        LicenseUri = 'https://example.test/license'
    }
    if ($OmitOptionalManifestMetadata) {
        $null = $manifest.Remove('Tags')
        $null = $manifest.Remove('ProjectUri')
        $null = $manifest.Remove('ReleaseNotes')
        $null = $manifest.Remove('LicenseUri')
    }

    return [pscustomobject]@{
        ProjectName = 'PackageProject'
        Version = '2.3.4'
        ProjectRoot = $Layout.ProjectRoot
        OutputModuleDir = $Layout.OutputModuleDir
        Description = 'Package project description'
        Manifest = $manifest
        Package = [ordered]@{
            Id = 'PackageProject'
            Types = @($PackageTypes)
            Latest = $Latest
            OutputDirectory = [ordered]@{
                Path = $Layout.PackageOutputDir
                Clean = $CleanOutputDirectory
            }
            PackageFileName = $PackageFileName
            AddVersionToFileName = $AddVersionToFileName
            Authors = @('Author One', 'Author Two')
            Description = 'Package project description'
        }
    }
}
