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

    It 'Get-Help explains how to disable and re-enable prerelease update notifications' {
        $buildHelp = Get-Help Invoke-NovaBuild -Full -ErrorAction Stop | Out-String
        $getPreferenceHelp = Get-Help Get-NovaUpdateNotificationPreference -Full -ErrorAction Stop | Out-String
        $setPreferenceHelp = Get-Help Set-NovaUpdateNotificationPreference -Full -ErrorAction Stop | Out-String

        $buildHelp | Should -Match 'DisablePrereleaseNotifications'
        $buildHelp | Should -Match 'EnablePrereleaseNotifications'
        $getPreferenceHelp | Should -Match 'Stable release notifications always remain enabled'
        $setPreferenceHelp | Should -Match 'DisablePrereleaseNotifications'
        $setPreferenceHelp | Should -Match 'EnablePrereleaseNotifications'
    }

    It 'Get-Help surfaces native WhatIf and Confirm support for mutating public commands' {
        foreach ($commandName in @(
            'Invoke-NovaBuild',
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
            Mock Invoke-NovaBuildUpdateNotification {}

            Invoke-NovaBuild

            Assert-MockCalled Build-Module -Times 1
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
                Test-NovaBuild -OutputVerbosity Normal -OutputRenderMode Plaintext
            }
            Assert = {
                param($Config)

                $Config.Output.Verbosity | Should -Be 'Normal'
                $Config.Output.RenderMode | Should -Be 'Plaintext'
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

