$script:remainingHelperCoverageTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'RemainingHelperCoverage.TestSupport.ps1')).Path
$global:remainingHelperCoverageTestSupportFunctionNameList = @(
    'Assert-TestNovaPackageArtifactContent',
    'Assert-TestNovaZipPackageArtifactContent',
    'Initialize-TestNovaPackageProjectLayout',
    'Get-TestNovaPackageProjectInfo'
)
$script:remainingHelperCoverageLocalHelperFunctionNameList = @(
    'Get-TestPackageOutputDirectorySafetyCases'
)

function Publish-RemainingHelperCoverageTestSupportFunctions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SupportPath,
        [Parameter(Mandatory)][string[]]$FunctionNameList
    )

    . $SupportPath

    foreach ($functionName in $FunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }
}

function Get-TestPackageOutputDirectorySafetyCases {
    [CmdletBinding()]
    param()

    $rootPath = if ($IsWindows) {
        'C:\'
    } else {
        '/'
    }

    return @(
        @{
            Name = 'filesystem root'
            OutputDirectory = $rootPath
            ProjectInfo = [pscustomobject]@{
                ProjectRoot = '/tmp/project-root'
                OutputModuleDir = '/tmp/project-root/dist/NovaModuleTools'
            }
            ErrorId = 'Nova.Configuration.PackageOutputDirectoryRootNotAllowed'
            Message = 'Package.OutputDirectory.Path cannot be a filesystem root when Package.OutputDirectory.Clean is true.'
            TargetObject = $rootPath
        }
        @{
            Name = 'protected project content'
            OutputDirectory = '/tmp/packages'
            ProjectInfo = [pscustomobject]@{
                ProjectRoot = '/tmp/packages/project-root'
                OutputModuleDir = '/tmp/project-root/dist/NovaModuleTools'
            }
            ErrorId = 'Nova.Configuration.PackageOutputDirectoryProtectedPath'
            Message = 'Package.OutputDirectory.Path cannot be cleaned because it would remove required project content: /tmp/packages/project-root'
            TargetObject = '/tmp/packages/project-root'
        }
    )
}

foreach ($functionName in $script:remainingHelperCoverageLocalHelperFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

Publish-RemainingHelperCoverageTestSupportFunctions -SupportPath $script:remainingHelperCoverageTestSupportPath -FunctionNameList $global:remainingHelperCoverageTestSupportFunctionNameList

BeforeAll {
    $remainingHelperCoverageTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'RemainingHelperCoverage.TestSupport.ps1')).Path
    $remainingHelperCoverageTestSupportFunctionNameList = @(
        'Assert-TestNovaPackageArtifactContent',
        'Assert-TestNovaZipPackageArtifactContent',
        'Initialize-TestNovaPackageProjectLayout',
        'Get-TestNovaPackageProjectInfo'
    )
    $remainingHelperCoverageLocalHelperFunctionNameList = @(
        'Get-TestSchemaResourceFilePath',
        'Get-TestSchemaResourceContent',
        'Get-TestPackageOutputDirectorySafetyCases',
        'Assert-TestPackageArtifactContentForType'
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

    It 'Get-LocalModulePathEntryList returns an empty list when PSModulePath is missing' {
        $originalModulePath = $env:PSModulePath

        try {
            $env:PSModulePath = $null

            InModuleScope $script:moduleName {
                @(Get-LocalModulePathEntryList) | Should -Be @()
            }
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Get-NovaEnvironmentVariableValue returns nothing when the variable name is blank' {
        InModuleScope $script:moduleName {
            Get-NovaEnvironmentVariableValue -Name '   ' | Should -BeNullOrEmpty
        }
    }

    It 'Get-NovaFirstConfiguredValue treats non-string values as configured' {
        InModuleScope $script:moduleName {
            Get-NovaFirstConfiguredValue -CandidateList @($null, '', 0, 'fallback') | Should -Be 0
            Get-NovaFirstConfiguredValue -CandidateList @($null, ' ', $false, 'fallback') | Should -BeFalse
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

    It 'Get-NovaModulePsDataValue returns null for null PSData and reads object properties when present' {
        InModuleScope $script:moduleName {
            $nullPsDataModule = [pscustomobject]@{
                PrivateData = [pscustomobject]@{PSData = $null}
            }
            $objectPsDataModule = [pscustomobject]@{
                PrivateData = [pscustomobject]@{
                    PSData = [pscustomobject]@{
                        Prerelease = 'preview'
                    }
                }
            }

            Get-NovaModulePsDataValue -Name 'Prerelease' -Module $nullPsDataModule | Should -BeNullOrEmpty
            Get-NovaModulePsDataValue -Name 'Prerelease' -Module $objectPsDataModule | Should -Be 'preview'
            Get-NovaModulePsDataValue -Name 'ReleaseNotes' -Module $objectPsDataModule | Should -BeNullOrEmpty
        }
    }

    It 'Get-NovaResolvedProjectManifestSettings returns a copy for manifest hashtables and an empty ordered table otherwise' {
        InModuleScope $script:moduleName {
            $projectDataWithManifest = @{
                Manifest = [ordered]@{
                    Author = 'Nova Author'
                    Description = 'Manifest description'
                }
            }
            $resolvedManifest = Get-NovaResolvedProjectManifestSettings -ProjectData $projectDataWithManifest

            $resolvedManifest['Author'] | Should -Be 'Nova Author'
            $resolvedManifest['Description'] | Should -Be 'Manifest description'
            $resolvedManifest.GetType().Name | Should -Be 'OrderedDictionary'

            $resolvedManifest['Author'] = 'Changed'
            $projectDataWithManifest.Manifest.Author | Should -Be 'Nova Author'

            (Get-NovaResolvedProjectManifestSettings -ProjectData @{}).Count | Should -Be 0
            (Get-NovaResolvedProjectManifestSettings -ProjectData @{Manifest = 'invalid'}).Count | Should -Be 0
        }
    }

    It 'Get-NovaProjectPackageOutputDirectorySettingsTable returns dictionary copies and wraps scalar paths' {
        InModuleScope $script:moduleName {
            $dictionarySettings = [ordered]@{
                OutputDirectory = [ordered]@{
                    Path = 'artifacts/packages'
                    Clean = $true
                }
            }
            $resolvedDictionarySettings = Get-NovaProjectPackageOutputDirectorySettingsTable -PackageSettings $dictionarySettings

            $resolvedDictionarySettings.Path | Should -Be 'artifacts/packages'
            $resolvedDictionarySettings.Clean | Should -BeTrue
            $resolvedDictionarySettings.GetType().Name | Should -Be 'OrderedDictionary'

            $resolvedDictionarySettings['Path'] = 'changed'
            $dictionarySettings.OutputDirectory.Path | Should -Be 'artifacts/packages'

            $resolvedStringSettings = Get-NovaProjectPackageOutputDirectorySettingsTable -PackageSettings @{OutputDirectory = 'dist/packages'}
            $resolvedStringSettings.Path | Should -Be 'dist/packages'

            $resolvedMissingSettings = Get-NovaProjectPackageOutputDirectorySettingsTable -PackageSettings @{}
            $resolvedMissingSettings.Path | Should -BeNullOrEmpty
        }
    }

    It 'Test-ProjectSchema validates the Build schema' {
        InModuleScope $script:moduleName {
            Mock Get-ResourceFilePath {
                param($FileName)

                if ($FileName -eq 'Schema-Build.json') {
                    return '/tmp/build-schema.json'
                }

                return '/tmp/pester-schema.json'
            }
            Mock Get-Content {
                param($Path)

                if ([string]$Path -eq '/tmp/build-schema.json') {
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

    It 'Test-ProjectSchema accepts Package.Types aliases case-insensitively' {
        $projectRoot = Join-Path $TestDrive 'accepts-mixed-case-aliases'
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
                Types = @('.NuPkg', 'ZIP')
            }
        } | ConvertTo-Json -Depth 5)
        Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Value $projectJson -Encoding utf8

        Push-Location $projectRoot
        try {
            InModuleScope $script:moduleName {
                Test-ProjectSchema -Schema Build | Should -BeTrue
            }
        }
        finally {
            Pop-Location
        }
    }

    It 'Test-ProjectSchema exposes a structured error for unsupported Package.Types values' {
        $projectRoot = Join-Path $TestDrive 'rejects-unsupported-type'
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
                Types = @('Tar')
            }
        } | ConvertTo-Json -Depth 5)
        Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Value $projectJson -Encoding utf8

        Push-Location $projectRoot
        try {
            InModuleScope $script:moduleName {
                $thrown = $null
                try {
                    Test-ProjectSchema -Schema Build
                }
                catch {
                    $thrown = $_
                }

                $thrown | Should -Not -BeNullOrEmpty
                $thrown.Exception.Message | Should -BeLike 'Invalid project.json for the Build schema: *The JSON is not valid with the schema*'
                $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Configuration.ProjectSchemaValidationFailed'
                $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidData)
                $thrown.TargetObject | Should -Be 'project.json'
            }
        }
        finally {
            Pop-Location
        }
    }

    It 'ConvertTo-NovaPackageType normalizes supported aliases and exposes a structured error for unsupported values' {
        InModuleScope $script:moduleName {
            ConvertTo-NovaPackageType -Type 'NuGet' | Should -Be 'NuGet'
            ConvertTo-NovaPackageType -Type '.nupkg' | Should -Be 'NuGet'
            ConvertTo-NovaPackageType -Type 'zip' | Should -Be 'Zip'
            ConvertTo-NovaPackageType -Type '.zip' | Should -Be 'Zip'

            $thrown = $null
            try {
                ConvertTo-NovaPackageType -Type 'tar.gz'
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Unsupported Package.Types value: tar.gz. Supported values: NuGet, Zip, .nupkg, .zip.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Configuration.UnsupportedPackageType'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidData)
            $thrown.TargetObject | Should -Be 'tar.gz'
        }
    }

    It 'Get-NovaPackageSettingValue reads dictionary and object values and returns nothing for missing entries' {
        InModuleScope $script:moduleName {
            Get-NovaPackageSettingValue -InputObject $null -Name 'Id' | Should -BeNullOrEmpty
            Get-NovaPackageSettingValue -InputObject @{Id = 'Nova.Package'} -Name 'Id' | Should -Be 'Nova.Package'
            Get-NovaPackageSettingValue -InputObject @{Id = 'Nova.Package'} -Name 'Missing' | Should -BeNullOrEmpty
            Get-NovaPackageSettingValue -InputObject ([pscustomobject]@{Id = 'Nova.Object.Package'}) -Name 'Id' | Should -Be 'Nova.Object.Package'
            Get-NovaPackageSettingValue -InputObject ([pscustomobject]@{Id = 'Nova.Object.Package'}) -Name 'Missing' | Should -BeNullOrEmpty
        }
    }

    It 'Merge-NovaPackageSettingTable merges dictionary and object settings while letting overrides win' {
        InModuleScope $script:moduleName {
            $result = Merge-NovaPackageSettingTable -BaseSettings ([pscustomobject]@{Id = 'base'; Authors = 'Base'}) -OverrideSettings @{Authors = 'Override'; Description = 'Package description'}

            $result.Id | Should -Be 'base'
            $result.Authors | Should -Be 'Override'
            $result.Description | Should -Be 'Package description'
            (Merge-NovaPackageSettingTable -BaseSettings $null -OverrideSettings $null).Count | Should -Be 0
        }
    }

    It 'Get-NovaConfiguredPackageTypeList uses configured values and defaults to NuGet when none are set' {
        InModuleScope $script:moduleName {
            @(Get-NovaConfiguredPackageTypeList -PackageSettings @{Types = @('NuGet', '', $null, 'Zip')}) | Should -Be @('NuGet', 'Zip')
            @(Get-NovaConfiguredPackageTypeList -PackageSettings ([pscustomobject]@{Types = @('Zip')})) | Should -Be @('Zip')
            @(Get-NovaConfiguredPackageTypeList -PackageSettings ([pscustomobject]@{Types = @('', $null)})) | Should -Be @('NuGet')
        }
    }

    It 'Test-NovaPackageLatestEnabled reads dictionary and object latest flags and defaults to false otherwise' {
        InModuleScope $script:moduleName {
            Test-NovaPackageLatestEnabled -PackageSettings @{Latest = $true} | Should -BeTrue
            Test-NovaPackageLatestEnabled -PackageSettings @{Types = @('NuGet')} | Should -BeFalse
            Test-NovaPackageLatestEnabled -PackageSettings ([pscustomobject]@{Latest = $true}) | Should -BeTrue
            Test-NovaPackageLatestEnabled -PackageSettings ([pscustomobject]@{Types = @('Zip')}) | Should -BeFalse
            Test-NovaPackageLatestEnabled -PackageSettings $null | Should -BeFalse
        }
    }

    It 'Get-NovaPackageMetadataList returns one entry per package type and optional latest variants' {
        InModuleScope $script:moduleName {
            Mock Get-NovaConfiguredPackageTypeList {@('NuGet', 'Zip')}
            Mock Test-NovaPackageLatestEnabled {$true}
            Mock Get-NovaPackageMetadata {"$( $PackageType )-latest:$( [bool]$Latest )"}

            $result = @(Get-NovaPackageMetadataList -ProjectInfo ([pscustomobject]@{Package = @{}}))

            $result | Should -Be @('NuGet-latest:False', 'NuGet-latest:True', 'Zip-latest:False', 'Zip-latest:True')
            Assert-MockCalled Get-NovaPackageMetadata -Times 4
        }
    }

    It 'Get-NovaPackageAuthorList normalizes string and enumerable author values' {
        InModuleScope $script:moduleName {
            @(Get-NovaPackageAuthorList -AuthorValue $null) | Should -Be @()
            @(Get-NovaPackageAuthorList -AuthorValue '   ') | Should -Be @()
            @(Get-NovaPackageAuthorList -AuthorValue '  Nova Author  ') | Should -Be @('Nova Author')
            @(Get-NovaPackageAuthorList -AuthorValue @(' Author A ', 'Author B', 'Author A', ' ')) | Should -Be @('Author A', 'Author B')
        }
    }

    It 'Get-NovaManifestValue reads dictionaries, objects, and returns null for missing object properties' {
        InModuleScope $script:moduleName {
            Get-NovaManifestValue -Manifest @{Author = 'Dictionary Author'} -Name 'Author' | Should -Be 'Dictionary Author'
            Get-NovaManifestValue -Manifest ([pscustomobject]@{Author = 'Object Author'}) -Name 'Author' | Should -Be 'Object Author'
            Get-NovaManifestValue -Manifest ([pscustomobject]@{Author = 'Object Author'}) -Name 'Tags' | Should -BeNullOrEmpty
        }
    }

    It 'Get-NovaPackageAuthorList rejects unsupported author value types' {
        InModuleScope $script:moduleName {
            $thrown = $null
            try {
                Get-NovaPackageAuthorList -AuthorValue 42
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Package.Authors must be a string or an array of strings.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Configuration.PackageAuthorsInvalidType'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidData)
            $thrown.TargetObject | Should -Be 42
        }
    }

    It 'Get-NovaPackageMetadata resolves explicit package types, trims fields, and uses a zip content root for zip packages' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
                Version = ' 1.2.3 '
                Manifest = [pscustomobject]@{}
                Package = [pscustomobject]@{
                    Id = ' Nova.Package '
                    Authors = @(' Author A ', 'Author B')
                    Description = ' Package description '
                    OutputDirectory = [pscustomobject]@{Clean = $true}
                    Types = @('zip')
                }
            }
            Mock ConvertTo-NovaPackageType {'Zip'}
            Mock Get-NovaPackageAuthorList {@('Author A', 'Author B')}
            Mock Get-NovaManifestValue {
                switch ($Name) {
                    'Tags' {
                        @('tools', '', 'module')
                    }
                    'ProjectUri' {
                        ' https://example.test/project '
                    }
                    'ReleaseNotes' {
                        ' https://example.test/release-notes '
                    }
                    'LicenseUri' {
                        ' https://example.test/license '
                    }
                    default {
                        $null
                    }
                }
            }
            Mock Get-NovaPackageFileName {'Nova.Package.latest.zip'}
            Mock Get-NovaPackageOutputDirectory {'/tmp/packages'}

            $result = Get-NovaPackageMetadata -ProjectInfo $projectInfo -PackageType 'zip' -Latest

            $result.Type | Should -Be 'Zip'
            $result.Latest | Should -BeTrue
            $result.Id | Should -Be 'Nova.Package'
            $result.Version | Should -Be '1.2.3'
            $result.Authors | Should -Be @('Author A', 'Author B')
            $result.Description | Should -Be 'Package description'
            $result.Tags | Should -Be @('tools', 'module')
            $result.ProjectUrl | Should -Be 'https://example.test/project'
            $result.ReleaseNotes | Should -Be 'https://example.test/release-notes'
            $result.LicenseUrl | Should -Be 'https://example.test/license'
            $result.PackagePath | Should -Be ([System.IO.Path]::Join('/tmp/packages', 'Nova.Package.latest.zip'))
            $result.ContentRoot | Should -Be 'NovaModuleTools'
        }
    }

    It 'Get-NovaPackageMetadata defaults to NuGet and content packages when no package type is configured' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
                Version = '1.2.3'
                Manifest = [pscustomobject]@{}
                Package = [pscustomobject]@{
                    Id = 'Nova.Package'
                    Authors = 'Author A'
                    Description = 'Package description'
                    OutputDirectory = [pscustomobject]@{Clean = $false}
                    Types = @('', $null)
                }
            }
            Mock ConvertTo-NovaPackageType {throw 'ConvertTo-NovaPackageType should not be called when the default NuGet type is used.'}
            Mock Get-NovaPackageAuthorList {@('Author A')}
            Mock Get-NovaManifestValue {
                if ($Name -eq 'Tags') {
                    return @()
                }

                return ''
            }
            Mock Get-NovaPackageFileName {'Nova.Package.nupkg'}
            Mock Get-NovaPackageOutputDirectory {'/tmp/packages'}

            $result = Get-NovaPackageMetadata -ProjectInfo $projectInfo

            $result.Type | Should -Be 'NuGet'
            $result.ContentRoot | Should -Be 'content/NovaModuleTools'
            $result.CleanOutputDirectory | Should -BeFalse
        }
    }

    It 'Assert-NovaPackageMetadata accepts complete metadata and rejects missing required fields and authors' {
        InModuleScope $script:moduleName {
            {
                Assert-NovaPackageMetadata -PackageMetadata ([pscustomobject]@{
                    Type = 'NuGet'
                    Id = 'Nova.Package'
                    Version = '1.2.3'
                    Description = 'Package description'
                    OutputDirectory = '/tmp/packages'
                    PackageFileName = 'Nova.Package.nupkg'
                    PackagePath = '/tmp/packages/Nova.Package.nupkg'
                    Authors = @('Author A')
                })
            } | Should -Not -Throw

            $missingField = $null
            try {
                Assert-NovaPackageMetadata -PackageMetadata ([pscustomobject]@{
                    Type = ''
                    Id = 'Nova.Package'
                    Version = '1.2.3'
                    Description = 'Package description'
                    OutputDirectory = '/tmp/packages'
                    PackageFileName = 'Nova.Package.nupkg'
                    PackagePath = '/tmp/packages/Nova.Package.nupkg'
                    Authors = @('Author A')
                })
            }
            catch {
                $missingField = $_
            }

            $missingField.FullyQualifiedErrorId | Should -Be 'Nova.Configuration.PackageMetadataValueMissing'
            $missingField.TargetObject | Should -Be 'Type'

            $missingAuthors = $null
            try {
                Assert-NovaPackageMetadata -PackageMetadata ([pscustomobject]@{
                    Type = 'NuGet'
                    Id = 'Nova.Package'
                    Version = '1.2.3'
                    Description = 'Package description'
                    OutputDirectory = '/tmp/packages'
                    PackageFileName = 'Nova.Package.nupkg'
                    PackagePath = '/tmp/packages/Nova.Package.nupkg'
                    Authors = @()
                })
            }
            catch {
                $missingAuthors = $_
            }

            $missingAuthors.FullyQualifiedErrorId | Should -Be 'Nova.Configuration.PackageMetadataValueMissing'
            $missingAuthors.TargetObject | Should -Be 'Authors'
        }
    }

    It 'Get-NovaPackageArtifactPatternInfo uses the configured pattern or defaults to the package id wildcard' {
        InModuleScope $script:moduleName {
            $defaultPattern = Get-NovaPackageArtifactPatternInfo -ProjectInfo ([pscustomobject]@{Package = [pscustomobject]@{Id = 'Nova.Package'; FileNamePattern = ' '}})

            $defaultPattern.Pattern | Should -Be 'Nova.Package*'
            $defaultPattern.ExplicitPackageType | Should -BeNullOrEmpty

            Mock ConvertTo-NovaPackageType {'Zip'}

            $zipPattern = Get-NovaPackageArtifactPatternInfo -ProjectInfo ([pscustomobject]@{Package = [pscustomobject]@{Id = 'Nova.Package'; FileNamePattern = 'artifacts/*.zip'}})

            $zipPattern.Pattern | Should -Be 'artifacts/*.zip'
            $zipPattern.ExplicitPackageType | Should -Be 'Zip'
        }
    }

    It 'Get-NovaPackageArtifactType resolves supported extensions and rejects unsupported upload file names' {
        InModuleScope $script:moduleName {
            Get-NovaPackageArtifactType -PackagePath '/tmp/Nova.Package.nupkg' | Should -Be 'NuGet'
            Get-NovaPackageArtifactType -PackagePath '/tmp/Nova.Package.zip' | Should -Be 'Zip'

            foreach ($packagePath in @('/tmp/package', '/tmp/Nova.Package', '/tmp/Nova.Package.tar.gz')) {
                $thrown = $null
                try {
                    Get-NovaPackageArtifactType -PackagePath $packagePath
                }
                catch {
                    $thrown = $_
                }

                $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.UnsupportedPackageUploadFileType'
                $thrown.TargetObject | Should -Be $packagePath
            }
        }
    }

    It 'Get-NovaPackageOutputDirectory returns rooted paths unchanged and resolves relative paths from the project root' {
        InModuleScope $script:moduleName {
            $relativeProject = [pscustomobject]@{ProjectRoot = '/tmp/project'; Package = [pscustomobject]@{OutputDirectory = [pscustomobject]@{Path = 'artifacts/packages'}}}
            $absoluteProject = [pscustomobject]@{ProjectRoot = '/tmp/project'; Package = [pscustomobject]@{OutputDirectory = '/tmp/packages'}}

            Get-NovaPackageOutputDirectory -ProjectInfo $relativeProject | Should -Be ([System.IO.Path]::Join('/tmp/project', 'artifacts/packages'))
            Get-NovaPackageOutputDirectory -ProjectInfo $absoluteProject | Should -Be '/tmp/packages'
        }
    }

    It 'Get-NovaPackageBaseFileName and Get-NovaPackageFileName respect version suffix and latest naming rules' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                Version = '1.2.3'
                Package = [pscustomobject]@{
                    PackageFileName = ' Custom.Package.zip '
                    AddVersionToFileName = $true
                }
            }

            Get-NovaPackageBaseFileName -ProjectInfo ([pscustomobject]@{Version = '1.2.3'; Package = [pscustomobject]@{PackageFileName = ''; AddVersionToFileName = $false}}) -PackageId 'Nova.Package' | Should -Be 'Nova.Package.1.2.3'
            Get-NovaPackageBaseFileName -ProjectInfo $projectInfo -PackageId 'Nova.Package' | Should -Be 'Custom.Package.1.2.3'
            Add-NovaPackageVersionSuffix -PackageFileName 'Custom.Package.1.2.3' -Version '1.2.3' | Should -Be 'Custom.Package.1.2.3'
            ConvertTo-NovaLatestPackageFileName -PackageFileName 'Custom.Package.1.2.3' -Version '1.2.3' | Should -Be 'Custom.Package.latest'
            ConvertTo-NovaLatestPackageFileName -PackageFileName 'Custom.Package' -Version '1.2.3' | Should -Be 'Custom.Package.latest'
            ConvertTo-NovaLatestPackageFileName -PackageFileName 'Custom.Package.latest' -Version '1.2.3' | Should -Be 'Custom.Package.latest'
            Get-NovaPackageFileName -ProjectInfo $projectInfo -PackageId 'Nova.Package' -PackageType 'zip' -Latest | Should -Be 'Custom.Package.latest.zip'
        }
    }

    It 'Get-NovaPackageUploadStatusCode returns integer status codes and nothing for null or missing responses' {
        InModuleScope $script:moduleName {
            Get-NovaPackageUploadStatusCode -Response $null | Should -BeNullOrEmpty
            Get-NovaPackageUploadStatusCode -Response ([pscustomobject]@{StatusCode = '201'}) | Should -Be 201
            Get-NovaPackageUploadStatusCode -Response ([pscustomobject]@{Body = 'ok'}) | Should -BeNullOrEmpty
        }
    }

    It 'Get-NovaPackageUploadAuthHeaderValue returns raw tokens for non-authorization headers or None schemes and defaults authorization to Bearer' {
        InModuleScope $script:moduleName {
            Get-NovaPackageUploadAuthHeaderValue -AuthSettings $null -HeaderName 'X-Api-Key' -Token 'secret-token' | Should -Be 'secret-token'
            Get-NovaPackageUploadAuthHeaderValue -AuthSettings $null -HeaderName 'Authorization' -Token 'secret-token' | Should -Be 'Bearer secret-token'
            Get-NovaPackageUploadAuthHeaderValue -AuthSettings ([pscustomobject]@{Scheme = 'None'}) -HeaderName 'Authorization' -Token 'secret-token' | Should -Be 'secret-token'
            Get-NovaPackageUploadAuthHeaderValue -AuthSettings $null -AuthenticationScheme ' Basic ' -HeaderName 'Authorization' -Token 'secret-token' | Should -Be 'Basic secret-token'
        }
    }

    It 'Initialize-NovaPackageOutputDirectory validates non-empty metadata, clears when requested, and creates missing directories' {
        InModuleScope $script:moduleName {
            $thrown = $null
            try {
                Initialize-NovaPackageOutputDirectory -ProjectInfo ([pscustomobject]@{}) -PackageMetadataList @()
            }
            catch {
                $thrown = $_
            }

            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.PackageMetadataListEmpty'
            $thrown.TargetObject | Should -Be 'PackageMetadataList'

            $metadata = [pscustomobject]@{OutputDirectory = '/tmp/packages'; CleanOutputDirectory = $true}
            Mock Clear-NovaPackageOutputDirectory {}
            Mock Test-Path {$false} -ParameterFilter {$LiteralPath -eq '/tmp/packages'}
            Mock New-Item {[pscustomobject]@{FullName = '/tmp/packages'}} -ParameterFilter {$ItemType -eq 'Directory' -and $Path -eq '/tmp/packages' -and $Force}

            Initialize-NovaPackageOutputDirectory -ProjectInfo ([pscustomobject]@{ProjectRoot = '/tmp/project'}) -PackageMetadataList @($metadata)

            Assert-MockCalled Clear-NovaPackageOutputDirectory -Times 1 -ParameterFilter {$OutputDirectory -eq '/tmp/packages'}
            Assert-MockCalled New-Item -Times 1 -ParameterFilter {$ItemType -eq 'Directory' -and $Path -eq '/tmp/packages' -and $Force}
        }
    }

    It 'Join-NovaPackageUploadUrl trims separators and escapes package file names' {
        InModuleScope $script:moduleName {
            Join-NovaPackageUploadUrl -Url 'https://example.test/api/' -UploadPath ' uploads /packages/ ' -PackageFileName 'Nova Package 1.2.3.nupkg' | Should -Be 'https://example.test/api/uploads /packages//Nova%20Package%201.2.3.nupkg'
            Join-NovaPackageUploadUrl -Url 'https://example.test/api' -PackageFileName 'Nova.Package.zip' | Should -Be 'https://example.test/api/Nova.Package.zip'
        }
    }

    It 'Resolve-NovaPackageUploadTypeList uses requested types, explicit artifact types, or metadata types depending on the inputs' {
        InModuleScope $script:moduleName {
            Mock Get-NovaPackageArtifactPatternInfo {[pscustomobject]@{Pattern = 'artifacts/*'; ExplicitPackageType = $null}}
            Mock ConvertTo-NovaPackageType {
                switch ($Type) {
                    '.zip' {
                        'Zip'
                    }
                    '.nupkg' {
                        'NuGet'
                    }
                    'zip' {
                        'Zip'
                    }
                    'nupkg' {
                        'NuGet'
                    }
                    default {
                        throw "Unsupported: $Type"
                    }
                }
            }
            Mock Get-NovaPackageMetadataList {@([pscustomobject]@{Type = 'NuGet'}, [pscustomobject]@{Type = 'Zip'}, [pscustomobject]@{Type = 'NuGet'})}

            @(Resolve-NovaPackageUploadTypeList -ProjectInfo ([pscustomobject]@{}) -PackageType @('zip', 'ZIP', 'nupkg')) | Should -Be @('Zip', 'NuGet')

            Mock Get-NovaPackageArtifactPatternInfo {[pscustomobject]@{Pattern = 'artifacts/*.zip'; ExplicitPackageType = 'Zip'}}
            @(Resolve-NovaPackageUploadTypeList -ProjectInfo ([pscustomobject]@{}) -PackageType @('zip', 'nupkg')) | Should -Be @('Zip')

            Mock Get-NovaPackageArtifactPatternInfo {[pscustomobject]@{Pattern = 'artifacts/*'; ExplicitPackageType = $null}}
            @(Resolve-NovaPackageUploadTypeList -ProjectInfo ([pscustomobject]@{})) | Should -Be @('NuGet', 'Zip')
        }
    }

    It 'Resolve-NovaPackageUploadTypeList exposes a structured conflict when requested types disagree with an explicit artifact pattern' {
        InModuleScope $script:moduleName {
            Mock Get-NovaPackageArtifactPatternInfo {[pscustomobject]@{Pattern = 'artifacts/*.zip'; ExplicitPackageType = 'Zip'}}
            Mock ConvertTo-NovaPackageType {'NuGet'}

            $thrown = $null
            try {
                Resolve-NovaPackageUploadTypeList -ProjectInfo ([pscustomobject]@{}) -PackageType @('nupkg')
            }
            catch {
                $thrown = $_
            }

            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.PackageUploadPatternConflict'
            $thrown.TargetObject | Should -Be 'artifacts/*.zip'
        }
    }

    It 'Test-NovaPathContainsPath returns true for identical or nested paths and false for siblings' {
        InModuleScope $script:moduleName {
            Test-NovaPathContainsPath -ParentPath '/tmp/project' -ChildPath '/tmp/project' | Should -BeTrue
            Test-NovaPathContainsPath -ParentPath '/tmp/project' -ChildPath '/tmp/project/dist/module' | Should -BeTrue
            Test-NovaPathContainsPath -ParentPath '/tmp/project' -ChildPath '/tmp/another' | Should -BeFalse
        }
    }

    It 'Get-AliasInFunctionFromFile returns aliases declared on the function' {
        $filePath = Join-Path $script:repoRoot 'src/public/UpdateNovaModuleTools.ps1'

        InModuleScope $script:moduleName -Parameters @{FilePath = $filePath} {
            param($FilePath)

            @(Get-AliasInFunctionFromFile -filePath $FilePath) | Should -Be @('Update-NovaModuleTools')
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

    It 'New-NovaErrorRecord and Stop-NovaOperation expose a stable error contract' {
        InModuleScope $script:moduleName {
            $errorRecord = New-NovaErrorRecord -Message 'Missing value for --path' -ErrorId 'Nova.Validation.MissingCliOptionValue' -Category InvalidArgument -TargetObject '--path'

            $errorRecord.FullyQualifiedErrorId | Should -Be 'Nova.Validation.MissingCliOptionValue'
            $errorRecord.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidArgument)
            $errorRecord.TargetObject | Should -Be '--path'
            $errorRecord.Exception.Message | Should -Be 'Missing value for --path'

            $thrown = $null
            try {
                Stop-NovaOperation -Message 'Missing value for --path' -ErrorId 'Nova.Validation.MissingCliOptionValue' -Category InvalidArgument -TargetObject '--path'
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.MissingCliOptionValue'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidArgument)
            $thrown.TargetObject | Should -Be '--path'
            $thrown.Exception.Message | Should -Be 'Missing value for --path'
        }
    }

    It 'Read-ProjectJsonData throws when project.json is <Name>' -ForEach @(
        @{
            Name = 'empty'
            FileName = 'empty-project.json'
            Content = ''
            ExpectedMessage = 'project.json is empty*'
            ExpectedErrorId = 'Nova.Configuration.ProjectJsonEmpty'
            ExpectedCategory = [System.Management.Automation.ErrorCategory]::InvalidData
        }
        @{
            Name = 'not valid JSON'
            FileName = 'invalid-project.json'
            Content = '{ invalid json }'
            ExpectedMessage = 'project.json is not valid JSON*'
            ExpectedErrorId = 'Nova.Configuration.ProjectJsonInvalidJson'
            ExpectedCategory = [System.Management.Automation.ErrorCategory]::ParserError
        }
        @{
            Name = 'not a top-level object'
            FileName = 'array-project.json'
            Content = '[1,2,3]'
            ExpectedMessage = 'project.json must contain a top-level JSON object*'
            ExpectedErrorId = 'Nova.Configuration.ProjectJsonTopLevelObjectRequired'
            ExpectedCategory = [System.Management.Automation.ErrorCategory]::InvalidData
        }
    ) {
        $projectJsonPath = Join-Path $TestDrive $_.FileName
        $_.Content | Set-Content -LiteralPath $projectJsonPath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{ProjectJsonPath = $projectJsonPath; ExpectedMessage = $_.ExpectedMessage; ExpectedErrorId = $_.ExpectedErrorId; ExpectedCategory = $_.ExpectedCategory} {
            param($ProjectJsonPath, $ExpectedMessage, $ExpectedErrorId, $ExpectedCategory)

            $thrown = $null
            try {
                Read-ProjectJsonData -ProjectJsonPath $ProjectJsonPath
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -BeLike $ExpectedMessage
            $thrown.FullyQualifiedErrorId | Should -Be $ExpectedErrorId
            $thrown.CategoryInfo.Category | Should -Be $ExpectedCategory
        }
    }

    It 'Read-NovaJsonFileData returns null when the file content is not valid JSON' {
        $jsonPath = Join-Path $TestDrive 'invalid-settings.json'
        '{ invalid json }' | Set-Content -LiteralPath $jsonPath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{JsonPath = $jsonPath} {
            param($JsonPath)

            Read-NovaJsonFileData -LiteralPath $JsonPath | Should -BeNullOrEmpty
        }
    }

    It 'Write-ProjectJsonData preserves nested objects, arrays, and unicode text when writing project.json' {
        $projectJsonPath = Join-Path $TestDrive 'written-project.json'

        InModuleScope $script:moduleName -Parameters @{ProjectJsonPath = $projectJsonPath} {
            param($ProjectJsonPath)

            $projectData = [ordered]@{
                ProjectName = 'NovaModuleTools'
                Description = 'ÆØÅ nested output'
                Version = '1.2.3'
                Manifest = [ordered]@{
                    Author = 'Stiwi'
                }
                Package = [ordered]@{
                    OutputDirectory = [ordered]@{
                        Path = 'artifacts/packages'
                        Clean = $true
                    }
                    Repositories = @(
                        [ordered]@{
                            Name = 'staging'
                            Auth = [ordered]@{
                                TokenEnvironmentVariable = 'NOVA_TOKEN'
                            }
                        }
                    )
                }
            }

            Write-ProjectJsonData -ProjectJsonPath $ProjectJsonPath -Data $projectData

            $result = Read-ProjectJsonData -ProjectJsonPath $ProjectJsonPath

            $result.Description | Should -Be 'ÆØÅ nested output'
            $result.Package.OutputDirectory.Path | Should -Be 'artifacts/packages'
            $result.Package.Repositories[0].Name | Should -Be 'staging'
            $result.Package.Repositories[0].Auth.TokenEnvironmentVariable | Should -Be 'NOVA_TOKEN'
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

            $thrown = $null
            try {
                Get-NovaHelpLocale -HelpMarkdownFiles $helpFiles
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Multiple help locales found in docs metadata: da-DK, en-US'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Configuration.HelpLocaleConflict'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidData)
            @($thrown.TargetObject) | Should -Be @('da-DK', 'en-US')
        }
    }

    It 'Get-NovaPackageAuthorList normalizes string and array author values' {
        InModuleScope $script:moduleName {
            Get-NovaPackageAuthorList -AuthorValue 'Author One' | Should -Be @('Author One')
            Get-NovaPackageAuthorList -AuthorValue @('Author One', ' Author Two ', 'Author One') | Should -Be @('Author One', 'Author Two')
        }
    }

    It 'Get-NovaPackageAuthorList exposes a structured configuration error for unsupported values' {
        InModuleScope $script:moduleName {
            $thrown = $null
            try {
                Get-NovaPackageAuthorList -AuthorValue ([pscustomobject]@{Name = 'Author One'})
            }
            catch {
                $thrown = $_
            }

            $thrown.Exception.Message | Should -Be 'Package.Authors must be a string or an array of strings.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Configuration.PackageAuthorsInvalidType'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidData)
        }
    }

    It 'Assert-NovaPackageOutputDirectoryCanBeCleared exposes structured validation errors for unsafe cleanup targets' -ForEach (Get-TestPackageOutputDirectorySafetyCases) {
        InModuleScope $script:moduleName -Parameters @{Case = $_} {
            param($Case)

            $thrown = $null
            try {
                Assert-NovaPackageOutputDirectoryCanBeCleared -ProjectInfo $Case.ProjectInfo -OutputDirectory $Case.OutputDirectory
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be $Case.Message
            $thrown.FullyQualifiedErrorId | Should -Be $Case.ErrorId
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidData)
            $thrown.TargetObject | Should -Be $Case.TargetObject
        }
    }

    It 'Get-NovaPackageContentItemList exposes structured errors when built output is missing or empty' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{OutputModuleDir = '/tmp/dist/NovaModuleTools'}
            $packageMetadata = [pscustomobject]@{ContentRoot = 'content'}

            Mock Test-Path {$false}

            $missingOutputError = $null
            try {
                Get-NovaPackageContentItemList -ProjectInfo $projectInfo -PackageMetadata $packageMetadata
            }
            catch {
                $missingOutputError = $_
            }

            $missingOutputError.Exception.Message | Should -Be 'Built module output not found: /tmp/dist/NovaModuleTools. Run Invoke-NovaBuild before packaging.'
            $missingOutputError.FullyQualifiedErrorId | Should -Be 'Nova.Environment.PackageBuildOutputNotFound'
            $missingOutputError.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::ObjectNotFound)
            $missingOutputError.TargetObject | Should -Be '/tmp/dist/NovaModuleTools'

            Mock Test-Path {$true}
            Mock Get-ChildItem {@()}

            $emptyOutputError = $null
            try {
                Get-NovaPackageContentItemList -ProjectInfo $projectInfo -PackageMetadata $packageMetadata
            }
            catch {
                $emptyOutputError = $_
            }

            $emptyOutputError.Exception.Message | Should -Be 'Built module output has no files to package: /tmp/dist/NovaModuleTools'
            $emptyOutputError.FullyQualifiedErrorId | Should -Be 'Nova.Workflow.PackageBuildOutputEmpty'
            $emptyOutputError.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidOperation)
            $emptyOutputError.TargetObject | Should -Be '/tmp/dist/NovaModuleTools'
        }
    }

    It 'New-NovaPackageArtifact writes the expected package structure for <ExpectedType>' -ForEach @(
        @{ProjectRootName = 'package-project'; PackageTypes = @('NuGet'); RequestedPackageType = 'NuGet'; ExpectedType = 'NuGet'}
        @{ProjectRootName = 'zip-package-project'; PackageTypes = @('Zip'); RequestedPackageType = 'Zip'; ExpectedType = 'Zip'}
    ) {
        $layout = Initialize-TestNovaPackageProjectLayout -ProjectRoot (Join-Path $TestDrive $_.ProjectRootName)
        $assertPackageContentByType = @{
            NuGet = {
                param($PackagePath)

                Assert-TestNovaPackageArtifactContent -PackagePath $PackagePath
            }
            Zip = {
                param($PackagePath)

                Assert-TestNovaZipPackageArtifactContent -PackagePath $PackagePath
            }
        }

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
        & $assertPackageContentByType[$_.ExpectedType] $packagePath
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

    It 'New-NovaPackageArtifacts returns an empty list when no package metadata was requested' {
        InModuleScope $script:moduleName {
            Mock Assert-NovaPackageMetadata {throw 'Package metadata validation should not run for an empty list.'}
            Mock Initialize-NovaPackageOutputDirectory {throw 'Output directory initialization should not run for an empty list.'}
            Mock New-NovaPackageArtifact {throw 'Package creation should not run for an empty list.'}

            $result = @(New-NovaPackageArtifacts -ProjectInfo ([pscustomobject]@{ProjectRoot = '/tmp/project'}) -PackageMetadataList @())

            $result | Should -Be @()
            Assert-MockCalled Assert-NovaPackageMetadata -Times 0
            Assert-MockCalled Initialize-NovaPackageOutputDirectory -Times 0
            Assert-MockCalled New-NovaPackageArtifact -Times 0
        }
    }

    It 'New-NovaPackageArtifact rejects unsupported package types with a structured validation error' {
        InModuleScope $script:moduleName {
            Mock Assert-NovaPackageMetadata {}

            $thrown = $null
            try {
                New-NovaPackageArtifact -ProjectInfo ([pscustomobject]@{OutputModuleDir = '/tmp/dist/NovaModuleTools'}) -PackageMetadata ([pscustomobject]@{
                    Type = 'Tar'
                    Latest = $false
                    Id = 'PackageProject'
                    Version = '2.3.4'
                    PackageFileName = 'PackageProject.2.3.4.tar'
                    PackagePath = '/tmp/packages/PackageProject.2.3.4.tar'
                    OutputDirectory = '/tmp/packages'
                }) -OutputDirectoryReady
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Unsupported package type: Tar'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.UnsupportedPackageArtifactType'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidArgument)
            $thrown.TargetObject | Should -Be 'Tar'
        }
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

    It 'New-NovaPackageArtifacts appends the project version to a custom PackageFileName when AddVersionToFileName is true' {
        $layout = Initialize-TestNovaPackageProjectLayout -ProjectRoot (Join-Path $TestDrive 'versioned-custom-package-name-project')

        $result = InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (Get-TestNovaPackageProjectInfo -Layout $layout -CleanOutputDirectory $true -PackageTypes @('NuGet', 'Zip') -Latest $true -PackageFileName 'AgentInstaller' -AddVersionToFileName $true)
        } {
            param($ProjectInfo)

            $packageMetadataList = @(Get-NovaPackageMetadataList -ProjectInfo $ProjectInfo)
            @(New-NovaPackageArtifacts -ProjectInfo $ProjectInfo -PackageMetadataList $packageMetadataList)
        }

        $result.PackageFileName | Should -Be @(
            'AgentInstaller.2.3.4.nupkg',
            'AgentInstaller.latest.nupkg',
            'AgentInstaller.2.3.4.zip',
            'AgentInstaller.latest.zip'
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
