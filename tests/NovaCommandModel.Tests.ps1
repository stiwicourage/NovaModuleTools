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
    . $testSupportPath

    $helpMetadata = & {
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

    It 'build output includes the generated external help file' {
        Test-Path -LiteralPath $script:helpXmlPath | Should -BeTrue
    }

    It 'build output includes the bundled nova launcher resource' {
        Test-Path -LiteralPath (Join-Path $distModuleDir 'resources/nova') | Should -BeTrue
    }

    It 'build output includes the packaged example project resource' {
        Test-Path -LiteralPath (Join-Path $distModuleDir 'resources/example/project.json') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $distModuleDir 'resources/example/src/public/Get-ExampleGreeting.ps1') | Should -BeTrue
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

    It 'Get-Help surfaces native WhatIf and Confirm support for mutating public commands' {
        foreach ($commandName in @(
            'Invoke-NovaBuild',
            'Test-NovaBuild',
            'Publish-NovaModule',
            'Invoke-NovaRelease',
            'New-NovaModule',
            'Install-NovaCli',
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

            Invoke-NovaBuild

            Assert-MockCalled Build-Module -Times 1
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

            $result = Invoke-NovaBuild -WhatIf

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Reset-ProjectDist -Times 0
            Assert-MockCalled Build-Module -Times 0
            Assert-MockCalled Build-Manifest -Times 0
            Assert-MockCalled Build-Help -Times 0
            Assert-MockCalled Copy-ProjectResource -Times 0
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

    It 'Test-NovaBuild -WhatIf skips Pester execution and artifact creation' {
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
            Mock Test-Path {$false}
            Mock New-Item {throw 'should not create artifacts'}
            Mock Invoke-Pester {throw 'should not run tests'}

            $result = Test-NovaBuild -WhatIf

            $result | Should -BeNullOrEmpty
            Assert-MockCalled New-Item -Times 0
            Assert-MockCalled Invoke-Pester -Times 0
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

    It 'Invoke-NovaRelease -WhatIf forwards preview mode through the nested workflow' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $publishAction = {
                param($ProjectInfo, $ModuleDirectoryPath)

                Publish-NovaBuiltModuleToDirectory @PSBoundParameters
            }

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-Command {
                [pscustomobject]@{ScriptBlock = $publishAction}
            } -ParameterFilter {$Name -eq 'Publish-NovaBuiltModuleToDirectory' -and $CommandType -eq 'Function'}
            Mock Get-LocalModulePath {'/tmp/modules'}
            Mock Invoke-NovaBuild {$script:steps += "build:$WhatIfPreference"}
            Mock Test-NovaBuild {$script:steps += "test:$WhatIfPreference"}
            Mock Update-NovaModuleVersion {
                $script:steps += "bump:$WhatIfPreference"
                [pscustomobject]@{PreviousVersion = '1.0.0'; NewVersion = '1.0.0'; Label = 'Patch'; CommitCount = 0}
            }
            Mock Publish-NovaBuiltModuleToDirectory {$script:steps += "publish:$WhatIfPreference"}

            $result = Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path -WhatIf

            $script:steps -join ',' | Should -Be 'build:True,test:True,bump:True,build:True,publish:True'
            $result.NewVersion | Should -Be '1.0.0'
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

    It 'Publish-NovaModule -WhatIf forwards preview mode to build, test, and publish helpers' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $publishAction = {
                param($ProjectInfo, $ModuleDirectoryPath)

                Publish-NovaBuiltModuleToDirectory @PSBoundParameters
            }

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-Command {
                [pscustomobject]@{ScriptBlock = $publishAction}
            } -ParameterFilter {$Name -eq 'Publish-NovaBuiltModuleToDirectory' -and $CommandType -eq 'Function'}
            Mock Get-LocalModulePath {'/tmp/modules'}
            Mock Invoke-NovaBuild {$script:steps += "build:$WhatIfPreference"}
            Mock Test-NovaBuild {$script:steps += "test:$WhatIfPreference"}
            Mock Publish-NovaBuiltModuleToDirectory {$script:steps += "publish:$WhatIfPreference"}

            $result = Publish-NovaModule -Local -WhatIf

            $result | Should -BeNullOrEmpty
            $script:steps -join ',' | Should -Be 'build:True,test:True,publish:True'
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

        $publishSource.IndexOf('Resolve-NovaPublishInvocation') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Invoke-NovaBuild') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Resolve-NovaPublishInvocation') | Should -BeLessThan $publishSource.IndexOf('Invoke-NovaBuild')
    }

    It 'Get-NovaCliConfirmDecision approves Yes and Yes to All, and cancels No, No to All, and Suspend' {
        InModuleScope $script:moduleName {
            foreach ($testCase in @(
                @{Key = 'Y'; Expected = $true},
                @{Key = 'A'; Expected = $true},
                @{Key = 'N'; Expected = $false},
                @{Key = 'L'; Expected = $false},
                @{Key = 'S'; Expected = $false},
                @{Key = 'y'; Expected = $true},
                @{Key = 'n'; Expected = $false}
            )) {
                $result = Get-NovaCliConfirmDecision -KeyChar ([char]$testCase.Key)
                $result | Should -Be $testCase.Expected
            }

            Get-NovaCliConfirmDecision -KeyChar ([char]'?') | Should -BeNullOrEmpty
        }
    }

    It 'Update-NovaModuleVersion -WhatIf previews the calculated next version without persisting it' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Version = '1.0.0'
                    ProjectJSON = '/tmp/project.json'
                }
            }
            Mock Get-GitCommitMessageForVersionBump {@('feat: add change')}
            Mock Get-VersionLabelFromCommitSet {'Minor'}
            Mock Get-NovaVersionUpdatePlan {
                [pscustomobject]@{
                    ProjectFile = '/tmp/project.json'
                    CurrentVersion = [semver]'1.0.0'
                    NewVersion = [semver]'1.1.0'
                }
            }
            Mock Set-NovaModuleVersion {}

            $result = Update-NovaModuleVersion -Path (Get-Location).Path -WhatIf

            $result.PreviousVersion | Should -Be '1.0.0'
            $result.NewVersion | Should -Be '1.1.0'
            $result.Label | Should -Be 'Minor'
            Assert-MockCalled Set-NovaModuleVersion -Times 0
        }
    }

    It 'Update-NovaModuleVersion returns no output when the CLI confirm prompt declines the bump' {
        InModuleScope $script:moduleName {
            $originalCliConfirm = $env:NOVA_CLI_CONFIRM_BUMP
            $env:NOVA_CLI_CONFIRM_BUMP = '1'

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Version = '1.0.0'
                    ProjectJSON = '/tmp/project.json'
                }
            }
            Mock Get-GitCommitMessageForVersionBump {@('feat: add change')}
            Mock Get-VersionLabelFromCommitSet {'Minor'}
            Mock Get-NovaVersionUpdatePlan {
                [pscustomobject]@{
                    ProjectFile = '/tmp/project.json'
                    CurrentVersion = [semver]'1.0.0'
                    NewVersion = [semver]'1.1.0'
                }
            }
            Mock Confirm-NovaCliBumpAction {$false}
            Mock Set-NovaModuleVersion {}

            try {
                $result = Update-NovaModuleVersion -Path (Get-Location).Path
            }
            finally {
                if ($null -eq $originalCliConfirm) {
                    Remove-Item Env:NOVA_CLI_CONFIRM_BUMP -ErrorAction SilentlyContinue
                }
                else {
                    $env:NOVA_CLI_CONFIRM_BUMP = $originalCliConfirm
                }
            }

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Confirm-NovaCliBumpAction -Times 1
            Assert-MockCalled Set-NovaModuleVersion -Times 0
        }
    }

    It 'Install-NovaCli copies the launcher and the installed command returns CLI help' {
        $targetDirectory = Join-Path $TestDrive 'bin'
        $installedPath = Join-Path $targetDirectory 'nova'
        $installedModuleVersion = (Get-Module $script:moduleName).Version.ToString()
        $expectedProjectVersionText = "$( $script:projectInfo.ProjectName ) $( $script:projectInfo.Version )"
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
            Push-Location $script:projectInfo.ProjectRoot
            try {
                $projectVersionOutput = & $installedPath version 2>&1
                $projectVersionText = @($projectVersionOutput) -join [Environment]::NewLine
                $projectVersionExitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }

            $result.CommandName | Should -Be 'nova'
            $result.InstalledPath | Should -Be $installedPath
            $result.DestinationDirectory | Should -Be $targetDirectory
            (Test-Path -LiteralPath $installedPath) | Should -BeTrue
            $helpExitCode | Should -Be 0
            $versionExitCode | Should -Be 0
            $projectVersionExitCode | Should -Be 0
            $helpText | Should -Match 'usage: nova \[--version\] \[--help\] <command> \[<args>\]'
            $helpText | Should -Match 'version\s+Show the current project name and version from project.json'
            $versionText | Should -Be "$script:moduleName $installedModuleVersion"
            $projectVersionText | Should -Be $expectedProjectVersionText
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli forwards -Verbose from the standalone launcher to build output' {
        $targetDirectory = Join-Path $TestDrive 'verbose-bin'
        $installedPath = Join-Path $targetDirectory 'nova'
        $projectRoot = Join-Path $TestDrive 'CliVerboseBuildProject'
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"

        New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
        foreach ($dir in @('src/public', 'src/private', 'src/classes', 'src/resources', 'tests', 'docs')) {
            New-Item -ItemType Directory -Path (Join-Path $projectRoot $dir) -Force | Out-Null
        }

        @'
{
  "ProjectName": "CliVerboseBuildProject",
  "Description": "CLI verbose forwarding test project",
  "Version": "0.0.1",
  "CopyResourcesToModuleRoot": false,
  "Manifest": {
    "Author": "Test",
    "PowerShellHostVersion": "7.4",
    "GUID": "22222222-2222-2222-2222-222222222222",
    "Tags": [],
    "ProjectUri": ""
  },
  "Pester": {
    "TestResult": {
      "Enabled": true,
      "OutputFormat": "NUnitXml"
    },
    "Output": {
      "Verbosity": "Detailed"
    }
  }
}
'@ | Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Encoding utf8

        @'
function Invoke-TestCliVerbose {
    'ok'
}
'@ | Set-Content -LiteralPath (Join-Path $projectRoot 'src/public/Invoke-TestCliVerbose.ps1') -Encoding utf8

        try {
            Install-NovaCli -DestinationDirectory $targetDirectory -Force | Out-Null

            Push-Location $projectRoot
            try {
                $buildOutput = & $installedPath build -Verbose 2>&1
                $buildText = @($buildOutput) -join [Environment]::NewLine
                $buildExitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }

            $buildExitCode | Should -Be 0
            $buildText | Should -Match 'VERBOSE: Running NovaModuleTools Version:'
            $buildText | Should -Match 'VERBOSE: Buidling module psm1 file'
            (Test-Path -LiteralPath (Join-Path $projectRoot 'dist/CliVerboseBuildProject/CliVerboseBuildProject.psm1')) | Should -BeTrue
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli forwards -WhatIf from the standalone launcher without mutating build, bump, or publish state' {
        $targetDirectory = Join-Path $TestDrive 'whatif-bin'
        $installedPath = Join-Path $targetDirectory 'nova'
        $projectRoot = Join-Path $TestDrive 'CliWhatIfProject'
        $projectJsonPath = Join-Path $projectRoot 'project.json'
        $builtModulePath = Join-Path $projectRoot 'dist/CliWhatIfProject/CliWhatIfProject.psm1'
        $testResultPath = Join-Path $projectRoot 'artifacts/TestResults.xml'
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"

        Initialize-TestNovaCliProjectLayout -ProjectRoot $projectRoot
        Write-TestNovaCliProjectJson -ProjectRoot $projectRoot -ProjectName 'CliWhatIfProject' -ProjectGuid '33333333-3333-3333-3333-333333333333'
        Write-TestNovaCliPublicFunction -ProjectRoot $projectRoot -FunctionName 'Invoke-TestCliWhatIf'

        try {
            Initialize-TestGitRepository -ProjectRoot $projectRoot -CommitMessage 'feat: add cli whatif coverage'

            Install-NovaCli -DestinationDirectory $targetDirectory -Force | Out-Null

            $buildResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('build', '-WhatIf')
            $publishResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('publish', '--local', '-WhatIf')
            $bumpResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('bump', '-WhatIf')
            $versionAfterBump = (Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json).Version

            $buildResult.ExitCode | Should -Be 0
            $publishResult.ExitCode | Should -Be 0
            $bumpResult.ExitCode | Should -Be 0
            $buildResult.Text | Should -Match 'What if:'
            $publishResult.Text | Should -Match 'What if:'
            $publishResult.Text | Should -Not -Match 'Unknown argument:'
            $bumpResult.Text | Should -Match 'What if:'
            $bumpResult.Text | Should -Match '0\.0\.1\s+0\.1\.0\s+Minor\s+1'
            $bumpResult.Text | Should -Not -Match 'Version bumped to :'
            $versionAfterBump | Should -Be '0.0.1'
            (Test-Path -LiteralPath $builtModulePath) | Should -BeFalse
            (Test-Path -LiteralPath $testResultPath) | Should -BeFalse
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli rejects nova init -WhatIf with a clear CLI error' {
        $targetDirectory = Join-Path $TestDrive 'init-whatif-bin'
        $installedPath = Join-Path $targetDirectory 'nova'
        $workspaceRoot = Join-Path $TestDrive 'CliInitWhatIfRoot'
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"
        New-Item -ItemType Directory -Path $workspaceRoot -Force | Out-Null

        try {
            Install-NovaCli -DestinationDirectory $targetDirectory -Force | Out-Null
            $initResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $workspaceRoot -Arguments @('init', '-WhatIf')

            $initResult.ExitCode | Should -Not -Be 0
            $initResult.Text | Should -Match 'does not support -WhatIf'
            $initResult.Text | Should -Not -Match 'Not a valid path'
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli rejects positional init paths with a migration hint' {
        $targetDirectory = Join-Path $TestDrive 'init-positional-bin'
        $installedPath = Join-Path $targetDirectory 'nova'
        $workspaceRoot = Join-Path $TestDrive 'CliInitPositionalRoot'
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"
        New-Item -ItemType Directory -Path $workspaceRoot -Force | Out-Null

        try {
            Install-NovaCli -DestinationDirectory $targetDirectory -Force | Out-Null
            $initResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $workspaceRoot -Arguments @('init', 'some/path')

            $initResult.ExitCode | Should -Not -Be 0
            $initResult.Text | Should -Match 'positional paths are no longer accepted'
            $initResult.Text | Should -Match 'nova init -Path some/path'
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Invoke-NovaCli version returns the project name and version' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {[pscustomobject]@{ProjectName = 'AzureDevOpsAgentInstaller'; Version = '1.2.3'}}

            Invoke-NovaCli version | Should -Be 'AzureDevOpsAgentInstaller 1.2.3'
            Assert-MockCalled Get-NovaProjectInfo -Times 1 -ParameterFilter {-not $Version}
        }
    }

    It 'Invoke-NovaCli --version returns the installed NovaModuleTools name and version' {
        InModuleScope $script:moduleName -Parameters @{ModuleName = $script:moduleName} {
            param($ModuleName)

            Mock Get-NovaCliInstalledVersion {'9.9.9'}

            Invoke-NovaCli --version | Should -Be "$ModuleName 9.9.9"
            Assert-MockCalled Get-NovaCliInstalledVersion -Times 1
        }
    }

    It 'Invoke-NovaCli --help returns CLI help text' {
        InModuleScope $script:moduleName {
            $result = Invoke-NovaCli --help

            $result | Should -Match 'usage: nova \[--version\] \[--help\] <command> \[<args>\]'
            $result | Should -Match 'init\s+Create a new Nova module scaffold'
            $result | Should -Match 'version\s+Show the current project name and version from project.json'
            $result | Should -Match '--version\s+Show the installed NovaModuleTools module name and version'
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

    It 'Invoke-NovaCli forwards WhatIf to mutating routed commands' {
        InModuleScope $script:moduleName {
            Mock Publish-NovaModule {
                [pscustomobject]@{WhatIfSeen = $WhatIfPreference}
            }

            $result = Invoke-NovaCli publish --repository PSGallery --apikey key123 -WhatIf

            $result.WhatIfSeen | Should -BeTrue
        }
    }

    It 'Invoke-NovaCli init rejects -WhatIf with a clear error' {
        InModuleScope $script:moduleName {
            {Invoke-NovaCli init -WhatIf} | Should -Throw "*does not support -WhatIf*"
        }
    }

    It 'Invoke-NovaCli init rejects positional paths instead of treating them as -Path' {
        InModuleScope $script:moduleName {
            {Invoke-NovaCli init 'some/path'} | Should -Throw "*positional paths are no longer accepted*"
        }
    }

    It 'Invoke-NovaCli throws on unsupported argument' {
        InModuleScope $script:moduleName {
            {Invoke-NovaCli publish --bogus} | Should -Throw 'Unknown argument*'
        }
    }

    It 'Invoke-NovaCli throws on an unknown top-level command' {
        InModuleScope $script:moduleName {
            {Invoke-NovaCli banana} | Should -Throw 'Unknown command: <banana*'
        }
    }
}


