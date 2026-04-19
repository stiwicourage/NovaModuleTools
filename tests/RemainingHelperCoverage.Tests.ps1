$script:remainingHelperCoverageTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'RemainingHelperCoverage.TestSupport.ps1')).Path
$global:remainingHelperCoverageTestSupportFunctionNameList = @(
    'Assert-TestNovaPackageArtifactContent',
    'Assert-TestNovaZipPackageArtifactContent',
    'Initialize-TestNovaPackageProjectLayout',
    'Get-TestNovaPackageProjectInfo'
)

. $script:remainingHelperCoverageTestSupportPath

foreach ($functionName in $global:remainingHelperCoverageTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $remainingHelperCoverageTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'RemainingHelperCoverage.TestSupport.ps1')).Path
    $remainingHelperCoverageTestSupportFunctionNameList = @(
        'Assert-TestNovaPackageArtifactContent',
        'Assert-TestNovaZipPackageArtifactContent',
        'Initialize-TestNovaPackageProjectLayout',
        'Get-TestNovaPackageProjectInfo'
    )

    . $remainingHelperCoverageTestSupportPath

    foreach ($functionName in $remainingHelperCoverageTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    $here = Split-Path -Parent $PSCommandPath
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Coverage for remaining manifest, JSON, and help-locale helpers' {
    It 'Format-NovaCliVersionString combines the component name and version' {
        InModuleScope $script:moduleName {
            Format-NovaCliVersionString -Name 'NovaModuleTools' -Version '1.9.10' | Should -Be 'NovaModuleTools 1.9.10'
        }
    }

    It 'Format-NovaCliVersionString keeps prerelease labels in the provided version string' {
        InModuleScope $script:moduleName {
            Format-NovaCliVersionString -Name 'NovaModuleTools' -Version '1.11.1-preview' | Should -Be 'NovaModuleTools 1.11.1-preview'
        }
    }

    It 'Get-LocalModulePathEntryList ignores blank PSModulePath segments' {
        $originalModulePath = $env:PSModulePath
        $separator = [IO.Path]::PathSeparator

        try {
            $env:PSModulePath = "/tmp/modules$separator$separator /tmp/alt-modules "

            InModuleScope $script:moduleName {
                Get-LocalModulePathEntryList | Should -Be @('/tmp/modules', '/tmp/alt-modules')
            }
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'module PSData helpers read release notes from both supported metadata shapes' -ForEach @(
        @{
            ModuleInfo = [pscustomobject]@{
                PrivateData = [pscustomobject]@{
                    PSData = @{ReleaseNotes = 'https://example.test/release-notes'}
                }
            }
            ExpectedReleaseNotes = 'https://example.test/release-notes'
            RawExpectedReleaseNotes = 'https://example.test/release-notes'
        }
        @{
            ModuleInfo = [pscustomobject]@{
                PrivateData = [pscustomobject]@{
                    PSData = [pscustomobject]@{ReleaseNotes = ' https://example.test/release-notes '}
                }
            }
            ExpectedReleaseNotes = 'https://example.test/release-notes'
            RawExpectedReleaseNotes = ' https://example.test/release-notes '
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{
            ModuleInfo = $ModuleInfo
            ExpectedReleaseNotes = $ExpectedReleaseNotes
            RawExpectedReleaseNotes = $RawExpectedReleaseNotes
        } {
            param($ModuleInfo, $ExpectedReleaseNotes, $RawExpectedReleaseNotes)

            Get-NovaModulePsDataValue -Name 'ReleaseNotes' -Module $ModuleInfo | Should -Be $RawExpectedReleaseNotes
            Get-NovaModuleReleaseNotesUri -Module $ModuleInfo | Should -Be $ExpectedReleaseNotes
        }
    }

    It 'Get-NovaModuleReleaseNotesUri returns nothing when release notes metadata is missing or blank' {
        InModuleScope $script:moduleName {
            $missingMetadataModule = [pscustomobject]@{
                PrivateData = [pscustomobject]@{PSData = [pscustomobject]@{}}
            }
            $blankMetadataModule = [pscustomobject]@{
                PrivateData = [pscustomobject]@{
                    PSData = @{ReleaseNotes = '   '}
                }
            }

            Get-NovaModuleReleaseNotesUri -Module $missingMetadataModule | Should -BeNullOrEmpty
            Get-NovaModuleReleaseNotesUri -Module $blankMetadataModule | Should -BeNullOrEmpty
        }
    }

    It 'Test-ProjectSchema validates the Build schema' {
        InModuleScope $script:moduleName {
            Mock Get-ResourceFilePath {
                if ($FileName -eq 'Schema-Build.json') {
                    return '/tmp/build-schema.json'
                }

                return '/tmp/pester-schema.json'
            }
            Mock Get-Content {
                if ($Path -eq '/tmp/build-schema.json') {
                    return '{"title":"build"}'
                }

                return '{"title":"pester"}'
            }
            Mock Test-Json {$true}

            Test-ProjectSchema -Schema Build | Should -BeTrue

            Assert-MockCalled Test-Json -Times 1 -ParameterFilter {
                $Path -eq 'project.json' -and $Schema -eq '{"title":"build"}'
            }
        }
    }

    It 'Test-ProjectSchema accepts Package.Types aliases case-insensitively and rejects unsupported values' -ForEach @(
        @{Name = 'accepts mixed-case aliases'; Types = @('.NuPkg', 'ZIP'); Expected = $true; Throws = $false; ErrorMessage = $null}
        @{Name = 'rejects unsupported type'; Types = @('Tar'); Expected = $null; Throws = $true; ErrorMessage = '*The JSON is not valid with the schema*'}
    ) {
        $projectRoot = Join-Path $TestDrive $_.Name.Replace(' ', '-')
        New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
        $projectJson = ([ordered]@{
            ProjectName = 'SchemaTypesProject'
            Description = 'Schema package types test'
            Version = '0.0.1'
            Manifest = [ordered]@{
                Author = 'Test Author'
                PowerShellHostVersion = '7.4'
                GUID = '99999999-9999-9999-9999-999999999999'
            }
            Package = [ordered]@{
                Types = $_.Types
            }
        } | ConvertTo-Json -Depth 5)
        Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Value $projectJson -Encoding utf8

        Push-Location $projectRoot
        try {
            InModuleScope $script:moduleName -Parameters @{Expected = $_.Expected; Throws = $_.Throws; ErrorMessage = $_.ErrorMessage} {
                param($Expected, $Throws, $ErrorMessage)

                if ($Throws) {
                    {Test-ProjectSchema -Schema Build} | Should -Throw $ErrorMessage
                    return
                }

                Test-ProjectSchema -Schema Build | Should -Be $Expected
            }
        }
        finally {
            Pop-Location
        }
    }

    It 'Get-AliasInFunctionFromFile returns aliases declared on the function' {
        $filePath = Join-Path $script:repoRoot 'src/public/InvokeNovaCli.ps1'

        InModuleScope $script:moduleName -Parameters @{FilePath = $filePath} {
            param($FilePath)

            @(Get-AliasInFunctionFromFile -filePath $FilePath) | Should -Be @('nova')
        }
    }

    It 'Get-AliasInFunctionFromFile returns nothing when the file cannot be parsed' {
        InModuleScope $script:moduleName {
            $result = Get-AliasInFunctionFromFile -filePath (Join-Path $TestDrive 'missing.ps1')

            $result | Should -BeNullOrEmpty
        }
    }

    It 'Get-OrderedScriptFileForDirectory returns an empty list when the directory is missing' {
        InModuleScope $script:moduleName {
            @(Get-OrderedScriptFileForDirectory -Directory (Join-Path $TestDrive 'missing-dir') -ProjectRoot $TestDrive -Recurse $false) | Should -Be @()
        }
    }

    It 'Get-FunctionNameFromFile returns every function name in the file' {
        $filePath = Join-Path $TestDrive 'Functions.ps1'
        @'
function Get-First {
}

function Get-Second {
}
'@ | Set-Content -LiteralPath $filePath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{FilePath = $filePath} {
            param($FilePath)

            @(Get-FunctionNameFromFile -filePath $FilePath) | Should -Be @('Get-First', 'Get-Second')
        }
    }

    It 'Get-FunctionNameFromFile returns an empty string when the file cannot be read' {
        InModuleScope $script:moduleName {
            Get-FunctionNameFromFile -filePath (Join-Path $TestDrive 'missing.ps1') | Should -Be ''
        }
    }

    It 'Read-ProjectJsonData returns a hashtable for a valid project object' {
        $projectJsonPath = Join-Path $TestDrive 'project.json'
        '{"ProjectName":"NovaModuleTools","Version":"1.2.3"}' | Set-Content -LiteralPath $projectJsonPath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{ProjectJsonPath = $projectJsonPath} {
            param($ProjectJsonPath)

            $result = Read-ProjectJsonData -ProjectJsonPath $ProjectJsonPath

            $result | Should -BeOfType 'hashtable'
            $result.ProjectName | Should -Be 'NovaModuleTools'
            $result.Version | Should -Be '1.2.3'
        }
    }

    It 'Read-ProjectJsonData throws when project.json is <Name>' -ForEach @(
        @{
            Name = 'empty'
            FileName = 'empty-project.json'
            Content = ''
            ExpectedMessage = 'project.json is empty*'
        }
        @{
            Name = 'not valid JSON'
            FileName = 'invalid-project.json'
            Content = '{ invalid json }'
            ExpectedMessage = 'project.json is not valid JSON*'
        }
        @{
            Name = 'not a top-level object'
            FileName = 'array-project.json'
            Content = '[1,2,3]'
            ExpectedMessage = 'project.json must contain a top-level JSON object*'
        }
    ) {
        $projectJsonPath = Join-Path $TestDrive $_.FileName
        $_.Content | Set-Content -LiteralPath $projectJsonPath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{ProjectJsonPath = $projectJsonPath; ExpectedMessage = $_.ExpectedMessage} {
            param($ProjectJsonPath, $ExpectedMessage)

            {Read-ProjectJsonData -ProjectJsonPath $ProjectJsonPath} | Should -Throw $ExpectedMessage
        }
    }

    It 'Get-NovaHelpLocale defaults to en-US when docs metadata has no locale' {
        $docPath = Join-Path $TestDrive 'No-Locale.md'
        @'
---
title: Test-Help
---
'@ | Set-Content -LiteralPath $docPath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{HelpFile = (Get-Item -LiteralPath $docPath)} {
            param($HelpFile)

            Get-NovaHelpLocale -HelpMarkdownFiles $HelpFile | Should -Be 'en-US'
        }
    }

    It 'Get-NovaHelpLocale throws when docs metadata contains conflicting locales' {
        $firstDocPath = Join-Path $TestDrive 'First.md'
        $secondDocPath = Join-Path $TestDrive 'Second.md'
        @'
---
Locale: da-DK
---
'@ | Set-Content -LiteralPath $firstDocPath -Encoding utf8
        @'
---
Locale: en-US
---
'@ | Set-Content -LiteralPath $secondDocPath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{FirstDocPath = $firstDocPath; SecondDocPath = $secondDocPath} {
            param($FirstDocPath, $SecondDocPath)

            $helpFiles = @(
                Get-Item -LiteralPath $FirstDocPath
                Get-Item -LiteralPath $SecondDocPath
            )

            {Get-NovaHelpLocale -HelpMarkdownFiles $helpFiles} | Should -Throw 'Multiple help locales found in docs metadata*'
        }
    }

    It 'Get-NovaPackageAuthorList normalizes string and array author values' {
        InModuleScope $script:moduleName {
            Get-NovaPackageAuthorList -AuthorValue 'Author One' | Should -Be @('Author One')
            Get-NovaPackageAuthorList -AuthorValue @('Author One', ' Author Two ', 'Author One') | Should -Be @('Author One', 'Author Two')
        }
    }

    It 'New-NovaPackageArtifact writes the expected package structure for <ExpectedType>' -ForEach @(
        @{ProjectRootName = 'package-project'; PackageTypes = @('NuGet'); RequestedPackageType = 'NuGet'; ExpectedType = 'NuGet'}
        @{ProjectRootName = 'zip-package-project'; PackageTypes = @('Zip'); RequestedPackageType = 'Zip'; ExpectedType = 'Zip'}
    ) {
        $layout = Initialize-TestNovaPackageProjectLayout -ProjectRoot (Join-Path $TestDrive $_.ProjectRootName)

        $packagePath = InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (Get-TestNovaPackageProjectInfo -Layout $layout -CleanOutputDirectory $true -PackageTypes $_.PackageTypes)
            RequestedPackageType = $_.RequestedPackageType
            ExpectedType = $_.ExpectedType
        } {
            param($ProjectInfo, $RequestedPackageType, $ExpectedType)

            $packageMetadata = Get-NovaPackageMetadata -ProjectInfo $ProjectInfo -PackageType $RequestedPackageType
            $result = New-NovaPackageArtifact -ProjectInfo $ProjectInfo -PackageMetadata $packageMetadata

            $result.Type | Should -Be $ExpectedType
            Test-Path -LiteralPath $result.PackagePath | Should -BeTrue
            $result.PackagePath
        }

        $packagePath | Should -Not -BeNullOrEmpty
        if ($_.ExpectedType -eq 'Zip') {
            Assert-TestNovaZipPackageArtifactContent -PackagePath $packagePath
            return
        }

        Assert-TestNovaPackageArtifactContent -PackagePath $packagePath
    }

    It 'New-NovaPackageArtifact honors Package.OutputDirectory.Clean when stale package files exist' -ForEach @(
        @{Name = 'clean output directory'; CleanOutputDirectory = $true; ExpectedStaleFile = $false}
        @{Name = 'preserve output directory'; CleanOutputDirectory = $false; ExpectedStaleFile = $true}
    ) {
        $layout = Initialize-TestNovaPackageProjectLayout -ProjectRoot (Join-Path $TestDrive $_.Name.Replace(' ', '-'))
        $staleFilePath = Join-Path $layout.PackageOutputDir 'stale.txt'
        New-Item -ItemType Directory -Path $layout.PackageOutputDir -Force | Out-Null
        'stale' | Set-Content -LiteralPath $staleFilePath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (Get-TestNovaPackageProjectInfo -Layout $layout -CleanOutputDirectory $_.CleanOutputDirectory)
        } {
            param($ProjectInfo)

            $packageMetadata = Get-NovaPackageMetadata -ProjectInfo $ProjectInfo
            $null = New-NovaPackageArtifact -ProjectInfo $ProjectInfo -PackageMetadata $packageMetadata
        }

        Test-Path -LiteralPath $staleFilePath | Should -Be $_.ExpectedStaleFile
    }

    It 'New-NovaPackageArtifacts creates both configured package types after a single output-directory initialization' {
        $layout = Initialize-TestNovaPackageProjectLayout -ProjectRoot (Join-Path $TestDrive 'multi-package-project')
        $staleFilePath = Join-Path $layout.PackageOutputDir 'stale.txt'
        New-Item -ItemType Directory -Path $layout.PackageOutputDir -Force | Out-Null
        'stale' | Set-Content -LiteralPath $staleFilePath -Encoding utf8

        $result = InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (Get-TestNovaPackageProjectInfo -Layout $layout -CleanOutputDirectory $true -PackageTypes @('NuGet', 'Zip'))
        } {
            param($ProjectInfo)

            $packageMetadataList = @(Get-NovaPackageMetadataList -ProjectInfo $ProjectInfo)
            @(New-NovaPackageArtifacts -ProjectInfo $ProjectInfo -PackageMetadataList $packageMetadataList)
        }

        $result.Type | Should -Be @('NuGet', 'Zip')
        $result.PackageFileName | Should -Be @('PackageProject.2.3.4.nupkg', 'PackageProject.2.3.4.zip')
        Test-Path -LiteralPath $staleFilePath | Should -BeFalse
        Assert-TestNovaPackageArtifactContent -PackagePath $result[0].PackagePath
        Assert-TestNovaZipPackageArtifactContent -PackagePath $result[1].PackagePath
    }

    It 'New-NovaPackageArtifacts also creates latest-named artifacts when Package.Latest is true' {
        $layout = Initialize-TestNovaPackageProjectLayout -ProjectRoot (Join-Path $TestDrive 'latest-package-project')

        $result = InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (Get-TestNovaPackageProjectInfo -Layout $layout -CleanOutputDirectory $true -PackageTypes @('NuGet', 'Zip') -Latest $true)
        } {
            param($ProjectInfo)

            $packageMetadataList = @(Get-NovaPackageMetadataList -ProjectInfo $ProjectInfo)
            @(New-NovaPackageArtifacts -ProjectInfo $ProjectInfo -PackageMetadataList $packageMetadataList)
        }

        $result.Type | Should -Be @('NuGet', 'NuGet', 'Zip', 'Zip')
        $result.Latest | Should -Be @($false, $true, $false, $true)
        $result.PackageFileName | Should -Be @(
            'PackageProject.2.3.4.nupkg',
            'PackageProject.latest.nupkg',
            'PackageProject.2.3.4.zip',
            'PackageProject.latest.zip'
        )
        @($result.PackagePath | ForEach-Object {Test-Path -LiteralPath $_}) | Should -Be @($true, $true, $true, $true)
    }

    It 'New-NovaPackageArtifact omits schema-optional manifest URI elements when they are not provided' {
        $layout = Initialize-TestNovaPackageProjectLayout -ProjectRoot (Join-Path $TestDrive 'package-project-without-optional-manifest-metadata')
        $packagePath = InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (Get-TestNovaPackageProjectInfo -Layout $layout -CleanOutputDirectory $true -OmitOptionalManifestMetadata)
        } {
            param($ProjectInfo)

            $packageMetadata = Get-NovaPackageMetadata -ProjectInfo $ProjectInfo
            (New-NovaPackageNuspecXml -PackageMetadata $packageMetadata)
        }

        $packagePath | Should -Not -Match '<projectUrl>'
        $packagePath | Should -Not -Match '<releaseNotes>'
        $packagePath | Should -Not -Match '<licenseUrl>'
        $packagePath | Should -Not -Match '<tags>'
    }
}
