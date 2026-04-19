$script:testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
$global:novaCommandModelTestSupportFunctionNameList = @(
    'Get-TestRegexMatchGroup'
    'ConvertTo-TestNormalizedText'
    'Get-TestModuleDisplayVersion'
    'Get-TestHelpLocaleFromMarkdownFiles'
    'Get-CommandHelpActivationTestCase'
    'Get-CommandHelpActivationTestCases'
    'Initialize-TestNovaCliProjectLayout'
    'Write-TestNovaCliProjectJson'
    'Write-TestNovaCliPublicFunction'
    'Initialize-TestNovaCliGitRepository'
    'Invoke-TestInstalledNovaCommand'
    'New-TestPesterConfigStub'
)
. $script:testSupportPath

foreach ($functionName in $global:novaCommandModelTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
    $here = Split-Path -Parent $PSCommandPath
    $repoRoot = Split-Path -Parent $here
    $script:projectInfo = Get-NovaProjectInfo -Path $repoRoot
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName

    $script:distModuleDir = Join-Path $repoRoot "dist/$script:moduleName"
    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
    . $testSupportPath
    foreach ($functionName in $global:novaCommandModelTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    $helpMetadata = & {
        $helpMarkdownFiles = Get-ChildItem -LiteralPath $script:projectInfo.DocsDir -Filter '*.md' -Recurse
        [pscustomobject]@{
            HelpLocale = Get-TestHelpLocaleFromMarkdownFiles -Files $helpMarkdownFiles
            HelpActivationTestCases = Get-CommandHelpActivationTestCases -DocsDir $script:projectInfo.DocsDir
        }
    }

    $script:helpLocale = $helpMetadata.HelpLocale
    $script:helpXmlPath = Join-Path $script:distModuleDir "$script:helpLocale/$script:moduleName-Help.xml"
    $script:helpActivationTestCases = $helpMetadata.HelpActivationTestCases
}

Describe 'Nova command model - project, help, and build behavior' {
    It 'Get-NovaProjectInfo -Version returns only version' {
        InModuleScope $script:moduleName {
            Mock Get-Content {'{"ProjectName":"X","Version":"9.9.9"}'}

            Get-NovaProjectInfo -Version | Should -Be '9.9.9'
        }
    }

    It 'Get-NovaProjectInfo throws when project.json is missing' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'missing-project-json'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null

            {Get-NovaProjectInfo -Path $projectRoot} | Should -Throw 'Not a project folder. project.json not found:*'
        }
    }

    It 'Get-NovaProjectInfo throws a clear error when project.json is empty' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'empty-project-json'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Value '' -Encoding utf8

            {Get-NovaProjectInfo -Path $projectRoot} | Should -Throw 'project.json is empty:*'
        }
    }

    It 'Get-NovaProjectInfo exposes CopyResourcesToModuleRoot with a false default when omitted' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'default-copy-resources-option'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
            $projectJson = ([ordered]@{
                ProjectName = 'DefaultCopyResourcesProject'
                Description = 'Defaulted option test'
                Version = '0.0.1'
                Manifest = [ordered]@{
                    Author = 'Test'
                    PowerShellHostVersion = '7.4'
                    GUID = '11111111-1111-1111-1111-111111111111'
                }
            } | ConvertTo-Json -Depth 5)

            Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Value $projectJson -Encoding utf8

            $projectInfo = Get-NovaProjectInfo -Path $projectRoot

            $projectInfo.PSObject.Properties.Name | Should -Contain 'CopyResourcesToModuleRoot'
            $projectInfo.CopyResourcesToModuleRoot | Should -BeFalse
        }
    }

    It 'Get-NovaProjectInfo exposes Package defaults when omitted' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'default-package-option'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
            $projectJson = ([ordered]@{
                ProjectName = 'DefaultPackageProject'
                Description = 'Default package option test'
                Version = '0.0.1'
                Manifest = [ordered]@{
                    Author = 'Test Author'
                    PowerShellHostVersion = '7.4'
                    GUID = '44444444-4444-4444-4444-444444444444'
                }
            } | ConvertTo-Json -Depth 5)

            Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Value $projectJson -Encoding utf8

            $projectInfo = Get-NovaProjectInfo -Path $projectRoot

            $projectInfo.Package.Id | Should -Be 'DefaultPackageProject'
            $projectInfo.Package.Types | Should -Be @('NuGet')
            $projectInfo.Package.OutputDirectory.Path | Should -Be ([System.IO.Path]::Join($projectRoot, 'artifacts/packages'))
            $projectInfo.Package.OutputDirectory.Clean | Should -BeTrue
            $projectInfo.Package.FileNamePattern | Should -Be 'DefaultPackageProject*'
            $projectInfo.Package.PackageFileName | Should -Be 'DefaultPackageProject.0.0.1.nupkg'
            $projectInfo.Package.Authors | Should -Be 'Test Author'
            $projectInfo.Package.Description | Should -Be 'Default package option test'
            $projectInfo.Package.Repositories | Should -Be @()
            $projectInfo.Package.Headers.Count | Should -Be 0
            $projectInfo.Package.Auth.Count | Should -Be 0
        }
    }

    It 'Get-NovaProjectInfo preserves optional generic package upload settings' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'package-upload-settings'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
            $projectJson = ([ordered]@{
                ProjectName = 'PackageUploadProject'
                Description = 'Package upload settings test'
                Version = '0.0.6'
                Manifest = [ordered]@{
                    Author = 'Test Author'
                    PowerShellHostVersion = '7.4'
                    GUID = '99999999-9999-9999-9999-999999999999'
                }
                Package = [ordered]@{
                    Types = @('Zip')
                    RawRepositoryUrl = 'https://packages.example/raw/'
                    UploadPath = 'releases/latest'
                    FileNamePattern = 'PackageUploadProject*'
                    Headers = [ordered]@{
                        'X-Trace-Id' = 'trace-123'
                    }
                    Auth = [ordered]@{
                        HeaderName = 'X-Api-Key'
                        TokenEnvironmentVariable = 'PACKAGE_UPLOAD_TOKEN'
                    }
                    Repositories = @(
                        [ordered]@{
                            Name = 'LocalNexus'
                            Url = 'https://packages.example/raw/local/'
                            UploadPath = 'modules'
                        }
                    )
                }
            } | ConvertTo-Json -Depth 6)

            Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Value $projectJson -Encoding utf8

            $projectInfo = Get-NovaProjectInfo -Path $projectRoot

            $projectInfo.Package.Types | Should -Be @('Zip')
            $projectInfo.Package.RawRepositoryUrl | Should -Be 'https://packages.example/raw/'
            $projectInfo.Package.UploadPath | Should -Be 'releases/latest'
            $projectInfo.Package.FileNamePattern | Should -Be 'PackageUploadProject*'
            $projectInfo.Package.Headers['X-Trace-Id'] | Should -Be 'trace-123'
            $projectInfo.Package.Auth.HeaderName | Should -Be 'X-Api-Key'
            $projectInfo.Package.Auth.TokenEnvironmentVariable | Should -Be 'PACKAGE_UPLOAD_TOKEN'
            $projectInfo.Package.Repositories.Count | Should -Be 1
            $projectInfo.Package.Repositories[0].Name | Should -Be 'LocalNexus'
            $projectInfo.Package.Repositories[0].Url | Should -Be 'https://packages.example/raw/local/'
            $projectInfo.Package.Repositories[0].UploadPath | Should -Be 'modules'
        }
    }

    It 'Get-NovaProjectInfo normalizes the legacy Package.OutputDirectory string to the new object shape' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'legacy-package-output-directory'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
            $projectJson = ([ordered]@{
                ProjectName = 'LegacyPackageProject'
                Description = 'Legacy package option test'
                Version = '0.0.2'
                Manifest = [ordered]@{
                    Author = 'Legacy Author'
                    PowerShellHostVersion = '7.4'
                    GUID = '55555555-5555-5555-5555-555555555555'
                }
                Package = [ordered]@{
                    OutputDirectory = 'custom/packages'
                }
            } | ConvertTo-Json -Depth 5)

            Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Value $projectJson -Encoding utf8

            $projectInfo = Get-NovaProjectInfo -Path $projectRoot

            $projectInfo.Package.Types | Should -Be @('NuGet')
            $projectInfo.Package.OutputDirectory.Path | Should -Be ([System.IO.Path]::Join($projectRoot, 'custom/packages'))
            $projectInfo.Package.OutputDirectory.Clean | Should -BeTrue
        }
    }

    It 'Get-NovaProjectInfo resolves Package.Types scenarios correctly' -ForEach @(
        @{
            Name = 'defaults empty arrays to NuGet'
            ProjectRootName = 'empty-package-types'
            ProjectName = 'EmptyTypesProject'
            Description = 'Empty package types test'
            Version = '0.0.3'
            Guid = '66666666-6666-6666-6666-666666666666'
            Types = @()
            ExpectedTypes = @('NuGet')
        }
        @{
            Name = 'normalizes aliases, casing, and duplicates'
            ProjectRootName = 'normalized-package-types'
            ProjectName = 'NormalizedTypesProject'
            Description = 'Normalized package types test'
            Version = '0.0.4'
            Guid = '77777777-7777-7777-7777-777777777777'
            Types = @('zip', '.NUPKG', 'NuGet', '.zip')
            ExpectedTypes = @('Zip', 'NuGet')
        }
        @{
            Name = 'rejects unsupported values'
            ProjectRootName = 'invalid-package-types'
            ProjectName = 'InvalidTypesProject'
            Description = 'Invalid package types test'
            Version = '0.0.5'
            Guid = '88888888-8888-8888-8888-888888888888'
            Types = @('Tar')
            ErrorMessage = 'Unsupported Package.Types value: Tar*'
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            $projectRoot = Join-Path $TestDrive $TestCase.ProjectRootName
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
            $projectJson = ([ordered]@{
                ProjectName = $TestCase.ProjectName
                Description = $TestCase.Description
                Version = $TestCase.Version
                Manifest = [ordered]@{
                    Author = 'Test Author'
                    PowerShellHostVersion = '7.4'
                    GUID = $TestCase.Guid
                }
                Package = [ordered]@{
                    Types = $TestCase.Types
                }
            } | ConvertTo-Json -Depth 5)

            Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Value $projectJson -Encoding utf8

            if ( $TestCase.ContainsKey('ErrorMessage')) {
                {Get-NovaProjectInfo -Path $projectRoot} | Should -Throw $TestCase.ErrorMessage
                return
            }

            (Get-NovaProjectInfo -Path $projectRoot).Package.Types | Should -Be $TestCase.ExpectedTypes
        }
    }

    It 'build output includes the generated external help file' {
        Test-Path -LiteralPath $script:helpXmlPath | Should -BeTrue
    }

    It 'build output includes the bundled nova launcher resource' {
        Test-Path -LiteralPath (Join-Path $script:distModuleDir 'resources/nova') | Should -BeTrue
    }

    It 'build output includes the packaged example project resource' {
        Test-Path -LiteralPath (Join-Path $script:distModuleDir 'resources/example/project.json') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $script:distModuleDir 'resources/example/src/public/Get-ExampleGreeting.ps1') | Should -BeTrue
    }

    It 'discovers command help files dynamically from docs' {
        $script:helpActivationTestCases | Should -Not -BeNullOrEmpty
    }

    It 'Get-Help loads synopsis for every command help file discovered in docs' {
        foreach ($testCase in $script:helpActivationTestCases) {
            $help = Get-Help $testCase.HelpTarget -ErrorAction Stop

            $help | Should -Not -BeNullOrEmpty -Because "Get-Help should activate $( $testCase.FileName )"
            $help.Name | Should -Be $testCase.HelpTarget -Because "$( $testCase.FileName ) should resolve to $( $testCase.HelpTarget )"
            $(
            if ( [string]::IsNullOrWhiteSpace($help.Synopsis)) {
                $null
            }
            else {
                ($help.Synopsis -replace '\s+', ' ').Trim()
            }
            ) | Should -Be $testCase.ExpectedSynopsis -Because "$( $testCase.FileName ) synopsis should come from the generated help"
        }
    }

    It 'Get-Help supports Detailed, Full, Examples, and Parameter views for every public command' {
        $commonParameterNames = @(
            'Verbose',
            'Debug',
            'ErrorAction',
            'WarningAction',
            'InformationAction',
            'ProgressAction',
            'ErrorVariable',
            'WarningVariable',
            'InformationVariable',
            'OutVariable',
            'OutBuffer',
            'PipelineVariable',
            'WhatIf',
            'Confirm'
        )

        foreach ($testCase in $script:helpActivationTestCases) {
            $command = Get-Command $testCase.HelpTarget -ErrorAction Stop
            $expectedParameterNames = @(
            $command.Parameters.Keys |
                    Where-Object {$_ -notin $commonParameterNames} |
                    Sort-Object
            )

            $detailedText = Get-Help $testCase.HelpTarget -Detailed -ErrorAction Stop | Out-String
            $fullText = Get-Help $testCase.HelpTarget -Full -ErrorAction Stop | Out-String
            $examplesText = Get-Help $testCase.HelpTarget -Examples -ErrorAction Stop | Out-String
            $detailedText | Should -Match 'DESCRIPTION' -Because "$( $testCase.HelpTarget ) should render a detailed help description"
            $detailedText | Should -Match 'PARAMETERS' -Because "$( $testCase.HelpTarget ) should render a detailed parameter section"
            $fullText | Should -Match 'INPUTS' -Because "$( $testCase.HelpTarget ) should render an inputs section"
            $fullText | Should -Match 'OUTPUTS' -Because "$( $testCase.HelpTarget ) should render an outputs section"
            $fullText | Should -Match 'NOTES' -Because "$( $testCase.HelpTarget ) should render a notes section"
            $examplesText | Should -Match 'PS>' -Because "$( $testCase.HelpTarget ) examples should use PowerShell prompt formatting"

            foreach ($parameterName in $expectedParameterNames) {
                $parameterText = Get-Help $testCase.HelpTarget -Parameter $parameterName -ErrorAction Stop | Out-String
                $parameterText | Should -Match ([regex]::Escape("-$parameterName")) -Because "$( $testCase.HelpTarget ) should document -$parameterName"
            }
        }
    }

    It 'Get-Help explains how to manage prerelease self-update eligibility' {
        $buildHelp = Get-Help Invoke-NovaBuild -Full -ErrorAction Stop | Out-String
        $updateHelp = Get-Help Update-NovaModuleTool -Full -ErrorAction Stop | Out-String
        $getPreferenceHelp = Get-Help Get-NovaUpdateNotificationPreference -Full -ErrorAction Stop | Out-String
        $setPreferenceHelp = Get-Help Set-NovaUpdateNotificationPreference -Full -ErrorAction Stop | Out-String

        $buildHelp | Should -Match 'Update-NovaModuleTool'
        $updateHelp | Should -Match 'prerelease'
        $getPreferenceHelp | Should -Match 'Stable self-updates remain available'
        $setPreferenceHelp | Should -Match 'DisablePrereleaseNotifications'
        $setPreferenceHelp | Should -Match 'EnablePrereleaseNotifications'
    }

    It 'Get-Help surfaces native WhatIf and Confirm support for mutating public commands' {
        foreach ($commandName in @(
            'Invoke-NovaBuild',
            'Pack-NovaModule',
            'Upload-NovaPackage',
            'Test-NovaBuild',
            'Publish-NovaModule',
            'Invoke-NovaRelease',
            'New-NovaModule',
            'Install-NovaCli',
            'Set-NovaUpdateNotificationPreference',
            'Update-NovaModuleVersion',
            'Invoke-NovaCli'
        )) {
            $fullText = Get-Help $commandName -Full -ErrorAction Stop | Out-String

            $fullText | Should -Match '-WhatIf' -Because "$commandName should surface native WhatIf support in full help"
            $fullText | Should -Match '-Confirm' -Because "$commandName should surface native Confirm support in full help"
        }
    }

    It 'Invoke-NovaBuild runs module build pipeline' {
        InModuleScope $script:moduleName {
            Mock Reset-ProjectDist {}
            Mock Build-Module {}
            Mock Get-NovaProjectInfo {[pscustomobject]@{FailOnDuplicateFunctionNames = $false; OutputModuleDir = '/tmp/dist/NovaModuleTools'}}
            Mock Build-Manifest {}
            Mock Build-Help {}
            Mock Copy-ProjectResource {}
            Mock New-NovaPackageArtifact {}
            Mock Invoke-NovaBuildUpdateNotification {}

            Invoke-NovaBuild

            Assert-MockCalled Build-Module -Times 1
            Assert-MockCalled New-NovaPackageArtifact -Times 0
            Assert-MockCalled Invoke-NovaBuildUpdateNotification -Times 1
        }
    }

    It 'Invoke-NovaBuild -WhatIf skips the build pipeline' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    FailOnDuplicateFunctionNames = $false
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Reset-ProjectDist {throw 'should not reset dist'}
            Mock Build-Module {throw 'should not build'}
            Mock Build-Manifest {throw 'should not build manifest'}
            Mock Build-Help {throw 'should not build help'}
            Mock Copy-ProjectResource {throw 'should not copy resources'}
            Mock Invoke-NovaBuildUpdateNotification {throw 'should not check for updates'}

            $result = Invoke-NovaBuild -WhatIf

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Reset-ProjectDist -Times 0
            Assert-MockCalled Build-Module -Times 0
            Assert-MockCalled Build-Manifest -Times 0
            Assert-MockCalled Build-Help -Times 0
            Assert-MockCalled Copy-ProjectResource -Times 0
            Assert-MockCalled Invoke-NovaBuildUpdateNotification -Times 0
        }
    }

    It 'Get-NovaHelpLocale reads locale from markdown front matter' {
        InModuleScope $script:moduleName {
            $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
            $null = New-Item -ItemType Directory -Path $tempRoot
            $docPath = Join-Path $tempRoot 'Invoke-NovaBuild.md'

            @'
---
Locale: da-DK
title: Invoke-NovaBuild
---
'@ | Set-Content -LiteralPath $docPath

            try {
                $result = Get-NovaHelpLocale -HelpMarkdownFiles (Get-Item -LiteralPath $docPath)

                $result | Should -Be 'da-DK'
            }
            finally {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Test-NovaBuild applies optional tag and output overrides to the Pester config' -ForEach @(
        @{
            Name = 'tag filters'
            IncludeOutput = $false
            Invoke = {
                Test-NovaBuild -TagFilter @('fast') -ExcludeTagFilter @('slow')
            }
            Assert = {
                param($Config)

                $Config.Filter.Tag | Should -Be @('fast')
                $Config.Filter.ExcludeTag | Should -Be @('slow')
            }
        }
        @{
            Name = 'output overrides'
            IncludeOutput = $true
            Invoke = {
                Test-NovaBuild -OutputVerbosity Normal -OutputRenderMode Ansi
            }
            Assert = {
                param($Config)

                $Config.Output.Verbosity | Should -Be 'Normal'
                $Config.Output.RenderMode | Should -Be 'Ansi'
            }
        }
        @{
            Name = 'verbosity-only override preserves render mode'
            IncludeOutput = $true
            Invoke = {
                Test-NovaBuild -OutputVerbosity Normal
            }
            Assert = {
                param($Config)

                $Config.Output.Verbosity | Should -Be 'Normal'
                $Config.Output.RenderMode | Should -Be 'Auto'
            }
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            $projectRoot = '/tmp/nova-project'
            $cfg = if ($TestCase.IncludeOutput) {
                New-TestPesterConfigStub -IncludeOutput
            }
            else {
                New-TestPesterConfigStub
            }

            Mock Test-ProjectSchema {}
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Pester = @{}
                    BuildRecursiveFolders = $true
                    TestsDir = 'tests'
                    ProjectRoot = $projectRoot
                }
            }
            Mock New-PesterConfiguration {$cfg}
            Mock Test-Path {$true}
            Mock Invoke-Pester {[pscustomobject]@{Result = 'Passed'}}

            & $TestCase.Invoke

            & $TestCase.Assert $cfg
            $cfg.TestResult.OutputPath | Should -Be ([System.IO.Path]::Join($projectRoot, 'artifacts', 'TestResults.xml'))
        }
    }

    It 'Test-NovaBuild rejects the removed Plaintext output render mode' {
        InModuleScope $script:moduleName {
            {Test-NovaBuild -OutputRenderMode Plaintext} | Should -Throw '*Cannot validate argument on parameter*OutputRenderMode*'
        }
    }

    It 'Test-NovaBuild -WhatIf skips Pester execution and artifact creation' {
        InModuleScope $script:moduleName {
            $projectRoot = '/tmp/nova-project'
            $cfg = New-TestPesterConfigStub -IncludeOutput

            Mock Test-ProjectSchema {}
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Pester = @{}
                    BuildRecursiveFolders = $true
                    TestsDir = 'tests'
                    ProjectRoot = $projectRoot
                }
            }
            Mock New-PesterConfiguration {$cfg}
            Mock Test-Path {$false}
            Mock New-Item {throw 'should not create artifacts'}
            Mock Invoke-Pester {throw 'should not run tests'}

            $result = Test-NovaBuild -WhatIf

            $result | Should -BeNullOrEmpty
            Assert-MockCalled New-Item -Times 0
            Assert-MockCalled Invoke-Pester -Times 0
        }
    }


}

