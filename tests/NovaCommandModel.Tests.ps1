BeforeAll {

    $testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path

    $here = Split-Path -Parent $PSCommandPath
    $repoRoot = Split-Path -Parent $here
    $script:projectInfo = Get-NovaProjectInfo -Path $repoRoot
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName

    $distModuleDir = Join-Path $repoRoot "dist/$script:moduleName"
    if (-not (Test-Path -LiteralPath $distModuleDir)) {
        throw "Expected built $script:moduleName module at: $distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $distModuleDir -Force

    $helpMetadata = & {
        . $testSupportPath

        $helpMarkdownFiles = Get-ChildItem -LiteralPath $script:projectInfo.DocsDir -Filter '*.md' -Recurse
        [pscustomobject]@{
            HelpLocale = Get-TestHelpLocaleFromMarkdownFiles -Files $helpMarkdownFiles
            HelpActivationTestCases = Get-CommandHelpActivationTestCases -DocsDir $script:projectInfo.DocsDir
        }
    }

    $script:helpLocale = $helpMetadata.HelpLocale
    $script:helpXmlPath = Join-Path $distModuleDir "$script:helpLocale/$script:moduleName-Help.xml"
    $script:helpActivationTestCases = $helpMetadata.HelpActivationTestCases
}

Describe 'Nova command model' {
    It 'Get-NovaProjectInfo -Version returns only version' {
        InModuleScope $script:moduleName {
            Mock Get-Content {'{"ProjectName":"X","Version":"9.9.9"}'}

            (Get-NovaProjectInfo).Version | Should -Be '9.9.9'
        }
    }

    It 'build output includes the generated external help file' {
        Test-Path -LiteralPath $script:helpXmlPath | Should -BeTrue
    }

    It 'build output includes the bundled nova launcher resource' {
        Test-Path -LiteralPath (Join-Path $distModuleDir 'resources/nova') | Should -BeTrue
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

    It 'Invoke-NovaBuild runs module build pipeline' {
        InModuleScope $script:moduleName {
            Mock Reset-ProjectDist {}
            Mock Build-Module {}
            Mock Get-NovaProjectInfo {[pscustomobject]@{FailOnDuplicateFunctionNames = $false}}
            Mock Build-Manifest {}
            Mock Build-Help {}
            Mock Copy-ProjectResource {}

            Invoke-NovaBuild

            Assert-MockCalled Build-Module -Times 1
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

    It 'Test-NovaBuild applies tag filters to Pester config' {
        InModuleScope $script:moduleName {
            $projectRoot = '/tmp/nova-project'
            $cfg = [pscustomobject]@{
                Run = [pscustomobject]@{Path = $null; PassThru = $false; Exit = $false; Throw = $false}
                Filter = [pscustomobject]@{Tag = @(); ExcludeTag = @()}
                TestResult = [pscustomobject]@{OutputPath = $null}
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

            Test-NovaBuild -TagFilter @('fast') -ExcludeTagFilter @('slow')

            $cfg.Filter.Tag | Should -Be @('fast')
            $cfg.Filter.ExcludeTag | Should -Be @('slow')
            $cfg.TestResult.OutputPath | Should -Be ([System.IO.Path]::Join($projectRoot, 'artifacts', 'TestResults.xml'))
        }
    }

    It 'Test-NovaBuild can override Pester console output settings' {
        InModuleScope $script:moduleName {
            $projectRoot = '/tmp/nova-project'
            $cfg = [pscustomobject]@{
                Run = [pscustomobject]@{Path = $null; PassThru = $false; Exit = $false; Throw = $false}
                Filter = [pscustomobject]@{Tag = @(); ExcludeTag = @()}
                Output = [pscustomobject]@{Verbosity = 'Detailed'; RenderMode = 'Auto'}
                TestResult = [pscustomobject]@{OutputPath = $null}
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

            Test-NovaBuild -OutputVerbosity Normal -OutputRenderMode Plaintext

            $cfg.Output.Verbosity | Should -Be 'Normal'
            $cfg.Output.RenderMode | Should -Be 'Plaintext'
            $cfg.TestResult.OutputPath | Should -Be ([System.IO.Path]::Join($projectRoot, 'artifacts', 'TestResults.xml'))
        }
    }

    It 'Invoke-NovaRelease runs build test bump build publish in order' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-LocalModulePath {'/tmp/modules'}
            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {$script:steps += 'test'}
            Mock Update-NovaModuleVersion {
                $script:steps += 'bump'
                return [pscustomobject]@{NewVersion = '1.0.1'}
            }
            Mock Test-Path {$true}
            Mock Remove-Item {}
            Mock Copy-Item {$script:steps += 'publish'}

            Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path | Out-Null

            $script:steps -join ',' | Should -Be 'build,test,bump,build,publish'
        }
    }

    It 'Invoke-NovaRelease does not bump version when tests fail' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-LocalModulePath {'/tmp/modules'}
            Mock Invoke-NovaBuild {}
            Mock Test-NovaBuild {throw 'boom'}
            Mock Update-NovaModuleVersion {}

            {Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path} | Should -Throw
            Assert-MockCalled Update-NovaModuleVersion -Times 0
        }
    }

    It 'Publish-NovaModule resolves local path before tests can reload helpers' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-LocalModulePath {
                $script:steps += 'resolve'
                '/tmp/modules'
            }
            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {
                $script:steps += 'test'
                Remove-Item function:Get-LocalModulePath -ErrorAction SilentlyContinue
            }
            Mock Test-Path {$true}
            Mock Remove-Item {}
            Mock Copy-Item {$script:steps += 'copy'}

            {Publish-NovaModule -Local} | Should -Not -Throw

            $script:steps -join ',' | Should -Be 'resolve,build,test,copy'
            Assert-MockCalled Copy-Item -Times 1 -ParameterFilter {$Destination -eq '/tmp/modules'}
        }
    }

    It 'Get-ResourceFilePath prefers project src resources during build' {
        InModuleScope $script:moduleName {
            $expected = [System.IO.Path]::GetFullPath('/tmp/project/src/resources/Schema-Build.json')
            $script:checkedPaths = @()

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ResourcesDir = '/tmp/project/src/resources'
                }
            }
            Mock Test-Path {
                param($LiteralPath)

                $script:checkedPaths += $LiteralPath
                return $LiteralPath -eq $expected
            }

            $result = Get-ResourceFilePath -FileName 'Schema-Build.json'

            $result | Should -Be $expected
            $script:checkedPaths[0] | Should -Be $expected
        }
    }

    It 'Get-LocalModulePath returns the first matching local module path for the current platform' {
        InModuleScope $script:moduleName {
            $originalModulePath = $env:PSModulePath
            $script:expectedModulePath = if ($IsWindows) {
                'C:\Users\Stiwi\Documents\PowerShell\Modules'
            }
            else {
                '/Users/stiwi.courage/.local/share/powershell/Modules'
            }

            $env:PSModulePath = if ($IsWindows) {
                'C:\Program Files\PowerShell\Modules;C:\Users\Stiwi\Documents\PowerShell\Modules;C:\Temp\Modules'
            }
            else {
                '/usr/local/share/powershell/Modules:/Users/stiwi.courage/.local/share/powershell/Modules:/tmp/modules'
            }

            Mock Test-Path {
                param($Path)
                return $Path -eq $script:expectedModulePath
            }

            try {
                Get-LocalModulePath | Should -Be $script:expectedModulePath
            }
            finally {
                $env:PSModulePath = $originalModulePath
            }
        }
    }

    It 'Get-LocalModulePath throws a platform-specific error when no matching path exists' {
        InModuleScope $script:moduleName {
            $originalModulePath = $env:PSModulePath
            $env:PSModulePath = if ($IsWindows) {
                'C:\Program Files\PowerShell\Modules;C:\Temp\Modules'
            }
            else {
                '/usr/local/share/powershell/Modules:/tmp/modules'
            }

            Mock Test-Path {$false}

            $expectedError = if ($IsWindows) {
                'No windows module path matching*'
            }
            else {
                'No macOS/Linux module path matching*'
            }

            try {
                {Get-LocalModulePath} | Should -Throw $expectedError
            }
            finally {
                $env:PSModulePath = $originalModulePath
            }
        }
    }

    It 'built module keeps Publish-NovaModule local path resolution before build and test' {
        $packagedModulePath = (Get-Module $script:moduleName).Path

        Test-Path -LiteralPath $packagedModulePath | Should -BeTrue

        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($packagedModulePath, [ref]$tokens, [ref]$errors)

        $errors.Count | Should -Be 0

        $publishFunction = $ast.Find(
                {
                    param($node)
                    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                            $node.Name -eq 'Publish-NovaModule'
                },
                $true
        )

        $publishFunction | Should -Not -BeNullOrEmpty
        $publishSource = $publishFunction.Extent.Text

        $publishSource.IndexOf('$PSBoundParameters.ContainsKey(''Repository'')') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Get-LocalModulePath') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Invoke-NovaBuild') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Get-LocalModulePath') | Should -BeLessThan $publishSource.IndexOf('Invoke-NovaBuild')
    }

    It 'Update-NovaModuleVersion -WhatIf does not invoke Set-NovaModuleVersion' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Version = '1.0.0'
                    ProjectJSON = '/tmp/project.json'
                }
            }
            Mock Get-GitCommitMessageForVersionBump {@('feat: add change')}
            Mock Get-VersionLabelFromCommitSet {'Minor'}
            Mock Set-NovaModuleVersion {}

            $result = Update-NovaModuleVersion -Path (Get-Location).Path -WhatIf

            $result.PreviousVersion | Should -Be '1.0.0'
            $result.NewVersion | Should -Be '1.0.0'
            $result.Label | Should -Be 'Minor'
            Assert-MockCalled Set-NovaModuleVersion -Times 0
        }
    }

    It 'Install-NovaCli copies the launcher and the installed command returns CLI help' {
        $targetDirectory = Join-Path $TestDrive 'bin'
        $installedPath = Join-Path $targetDirectory 'nova'
        $projectVersion = $script:projectInfo.Version
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"

        try {
            $result = Install-NovaCli -DestinationDirectory $targetDirectory -Force
            $helpOutput = & $installedPath --help 2>&1
            $helpText = @($helpOutput) -join [Environment]::NewLine
            $helpExitCode = $LASTEXITCODE
            $versionOutput = & $installedPath --version 2>&1
            $versionText = @($versionOutput) -join [Environment]::NewLine
            $versionExitCode = $LASTEXITCODE

            $result.CommandName | Should -Be 'nova'
            $result.InstalledPath | Should -Be $installedPath
            $result.DestinationDirectory | Should -Be $targetDirectory
            (Test-Path -LiteralPath $installedPath) | Should -BeTrue
            $helpExitCode | Should -Be 0
            $versionExitCode | Should -Be 0
            $helpText | Should -Match 'usage: nova \[--version\] \[--help\] <command> \[<args>\]'
            $versionText | Should -Match ([regex]::Escape($projectVersion))
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Invoke-NovaCli --version maps to Get-NovaProjectInfo -Version' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {'1.2.3'} -ParameterFilter {$Version}

            Invoke-NovaCli --version | Should -Be '1.2.3'
            Assert-MockCalled Get-NovaProjectInfo -Times 1 -ParameterFilter {$Version}
        }
    }

    It 'Invoke-NovaCli --help returns CLI help text' {
        InModuleScope $script:moduleName {
            $result = Invoke-NovaCli --help

            $result | Should -Match 'usage: nova \[--version\] \[--help\] <command> \[<args>\]'
            $result | Should -Match 'init\s+Create a new Nova module scaffold'
            $result | Should -Match 'publish\s+Build, test, and publish the module locally or to a repository'
        }
    }

    It 'Invoke-NovaCli publish forwards repository options' {
        InModuleScope $script:moduleName {
            Mock Publish-NovaModule {
                return [pscustomobject]@{
                    Repository = $Repository
                    ApiKey = $ApiKey
                }
            }

            $result = Invoke-NovaCli publish --repository PSGallery --apikey key123

            $result.Repository | Should -Be 'PSGallery'
            $result.ApiKey | Should -Be 'key123'
        }
    }

    It 'Invoke-NovaCli throws on unsupported argument' {
        InModuleScope $script:moduleName {
            {Invoke-NovaCli publish --bogus} | Should -Throw 'Unknown argument*'
        }
    }
}


