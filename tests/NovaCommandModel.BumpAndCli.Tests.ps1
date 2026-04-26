$script:testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path

<#
# Why we intentionally ignore CodeScene's warnings here
#
# This test file contains a large number of small helper functions that are used across multiple test cases to
# validate the behavior of the nova CLI confirmation and version bump workflows. To avoid unnecessary complexity
# in the test cases and to promote reuse of common test logic, these helper functions are defined in a separate
# test support script and imported into this test file.
#
# @CodeScene (disable:"Global Conditionals")
#>
$global:novaCommandModelBumpAndCliTestSupportFunctionNameList = @(
    'Publish-TestSupportFunctions'
    'Get-TestRegexMatchGroup'
    'ConvertTo-TestNormalizedText'
    'Assert-TestModuleIsBuilt'
    'Get-TestModuleDisplayVersion'
    'Get-TestHelpLocaleFromMarkdownFiles'
    'Get-CommandHelpActivationTestCase'
    'Get-CommandHelpActivationTestCases'
    'Get-TestModuleContextInfo'
    'Initialize-TestModuleContext'
    'Initialize-TestNovaCliProjectLayout'
    'Write-TestNovaCliProjectJson'
    'Write-TestNovaCliPublicFunction'
    'Initialize-TestNovaCliGitRepository'
    'Invoke-TestInstalledNovaCommand'
    'New-TestPesterConfigStub'
    'Assert-TestNovaCliConfirmDecisions'
    'Invoke-ReadNovaCliPromptKeyAssertion'
    'Invoke-GetNovaCliCommandPromptKeyAssertion'
    'Invoke-GetNovaCliCommandCancellationInfoAssertion'
    'Invoke-UpdateNovaModuleVersionDefaultPathAssertion'
    'Invoke-ConfirmNovaCliCommandActionEnterAssertion'
    'Invoke-ConfirmNovaCliCommandActionRetryAssertion'
    'Invoke-ConfirmNovaCliCommandActionCancellationAssertion'
)
. $script:testSupportPath

foreach ($functionName in $global:novaCommandModelBumpAndCliTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
    . $testSupportPath
    Publish-TestSupportFunctions -FunctionNameList $global:novaCommandModelBumpAndCliTestSupportFunctionNameList
    $moduleContext = Initialize-TestModuleContext -CommandPath $PSCommandPath -SupportPath $testSupportPath -FunctionNameList $global:novaCommandModelBumpAndCliTestSupportFunctionNameList
    $script:moduleName = $moduleContext.ModuleName
    $script:distModuleDir = $moduleContext.DistModuleDir
}

Describe 'Nova command model - bump and CLI confirmation behavior' {
    It 'Get-NovaCliConfirmDecision approves Yes and Yes to All, and cancels No, No to All, and Suspend' {
        Assert-TestNovaCliConfirmDecisions -ModuleName $script:moduleName
    }

    It 'Read-NovaCliPromptKey returns the expected result when console input <Name>' -ForEach @(
        @{Name = 'is available'; Expected = [char]'y'; ConsoleKeyChar = [char]'y'; Throws = $false}
        @{Name = 'fails'; Expected = [char]0; ConsoleKeyChar = [char]0; Throws = $true}
    ) {
        Invoke-ReadNovaCliPromptKeyAssertion -ModuleName $script:moduleName -TestCase $_
    }

    It 'Get-NovaCliCommandPromptKey returns the expected key when prompt input <Name>' -ForEach @(
        @{Name = 'uses the NOVA_CLI_CONFIRM_RESPONSE override'; EnvironmentResponse = 'later'; Expected = [char]'l'; PromptReadCount = 0}
        @{Name = 'must be read from the interactive prompt'; EnvironmentResponse = ''; Expected = [char]'n'; PromptReadCount = 1}
    ) {
        Invoke-GetNovaCliCommandPromptKeyAssertion -ModuleName $script:moduleName -TestCase $_
    }

    It 'Get-NovaCliCommandCancellationInfo returns the expected cancellation metadata for <Name>' -ForEach @(
        @{Name = 'Suspend'; Key = 'S'; ExpectedMessage = 'Suspend is not supported in nova CLI mode. Operation cancelled.'; ExpectedErrorId = 'Nova.Workflow.CliSuspendNotSupported'}
        @{Name = 'No'; Key = 'N'; ExpectedMessage = 'Operation cancelled.'; ExpectedErrorId = 'Nova.Workflow.CliOperationCancelled'}
    ) {
        Invoke-GetNovaCliCommandCancellationInfoAssertion -ModuleName $script:moduleName -TestCase $_
    }

    It 'Get-NovaVersionUpdateWorkflowContext prepares version bump state from project info and commit history' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    Version = '1.0.0'
                    ProjectJSON = '/tmp/project.json'
                }
            }
            Mock Get-GitCommitMessageForVersionBump {@('feat: add change', 'fix: patch bug')}
            Mock Get-NovaVersionLabelForBump {'Minor'}
            Mock Get-NovaVersionUpdatePlan {
                [pscustomobject]@{
                    NewVersion = [semver]'1.1.0'
                }
            }

            $result = Get-NovaVersionUpdateWorkflowContext -ProjectRoot '/tmp/project'

            $result.ProjectRoot | Should -Be '/tmp/project'
            $result.PreviousVersion | Should -Be '1.0.0'
            $result.NewVersion | Should -Be '1.1.0'
            $result.Label | Should -Be 'Minor'
            $result.CommitCount | Should -Be 2
            $result.Target | Should -Be 'project.json'
            $result.Action | Should -Be 'Update module version using Minor release label'
            $result.'ContinuousIntegrationRequested' | Should -BeFalse
            Assert-MockCalled Get-NovaVersionUpdatePlan -Times 1 -ParameterFilter {
                $ProjectInfo.ProjectName -eq 'NovaModuleTools' -and
                        $Label -eq 'Minor' -and
                        -not $PreviewRelease
            }
        }
    }

    It 'Get-NovaVersionUpdateWorkflowContext carries ContinuousIntegrationRequested when requested' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    Version = '1.0.0'
                    ProjectJSON = '/tmp/project.json'
                }
            }
            Mock Get-GitCommitMessageForVersionBump {@('feat: add change')}
            Mock Get-NovaVersionLabelForBump {'Minor'}
            Mock Get-NovaVersionUpdatePlan {
                [pscustomobject]@{
                    NewVersion = [semver]'1.1.0'
                }
            }

            $result = Get-NovaVersionUpdateWorkflowContext -ProjectRoot '/tmp/project' -ContinuousIntegrationRequested

            $result.'ContinuousIntegrationRequested' | Should -BeTrue
        }
    }

    It 'Get-NovaVersionUpdateCiActivatedCommand skips re-import when the current command already uses the built module' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-Command {
                [pscustomobject]@{
                    Module = [pscustomobject]@{Path = '/tmp/dist/NovaModuleTools/NovaModuleTools.psd1'}
                }
            } -ParameterFilter {$Name -eq 'Update-NovaModuleVersion' -and $CommandType -eq 'Function'}
            Mock Import-NovaBuiltModuleForCi {throw 'should not re-import when already activated'}

            $result = Get-NovaVersionUpdateCiActivatedCommand -ProjectRoot '/tmp/project'

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Import-NovaBuiltModuleForCi -Times 0
        }
    }

    It 'Get-NovaVersionUpdateCiActivatedCommand imports the built module and returns the rebound command when activation is needed' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }

            $script:getCommandCallCount = 0
            Mock Get-Command {
                $script:getCommandCallCount += 1
                if ($script:getCommandCallCount -eq 1) {
                    return [pscustomobject]@{
                        Name = 'Update-NovaModuleVersion'
                        Module = [pscustomobject]@{Path = '/tmp/installed/NovaModuleTools/NovaModuleTools.psd1'}
                    }
                }

                return [pscustomobject]@{
                    Name = 'Update-NovaModuleVersion'
                    Module = [pscustomobject]@{Path = '/tmp/dist/NovaModuleTools/NovaModuleTools.psd1'}
                }
            } -ParameterFilter {$Name -eq 'Update-NovaModuleVersion' -and $CommandType -eq 'Function'}
            Mock Import-NovaBuiltModuleForCi {}

            $result = Get-NovaVersionUpdateCiActivatedCommand -ProjectRoot '/tmp/project'

            $result.Name | Should -Be 'Update-NovaModuleVersion'
            $result.Module.Path | Should -Be '/tmp/dist/NovaModuleTools/NovaModuleTools.psd1'
            Assert-MockCalled Import-NovaBuiltModuleForCi -Times 1 -ParameterFilter {$ProjectInfo.ProjectName -eq 'NovaModuleTools'}
            Assert-MockCalled Get-Command -Times 2 -ParameterFilter {$Name -eq 'Update-NovaModuleVersion' -and $CommandType -eq 'Function'}
        }
    }

    It 'Invoke-NovaVersionUpdateWorkflow writes only when requested and still returns WhatIf results' {
        InModuleScope $script:moduleName {
            $workflowContext = [pscustomobject]@{
                ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                Label = 'Minor'
                PreviewRelease = $true
                PreviousVersion = '1.0.0'
                NewVersion = '1.1.0-preview'
                CommitCount = 2
            }
            Mock Set-NovaModuleVersion {}

            $whatIfResult = Invoke-NovaVersionUpdateWorkflow -WorkflowContext $workflowContext -WhatIfEnabled
            $runResult = Invoke-NovaVersionUpdateWorkflow -WorkflowContext $workflowContext -ShouldRun

            $whatIfResult.NewVersion | Should -Be '1.1.0-preview'
            $runResult.NewVersion | Should -Be '1.1.0-preview'
            Assert-MockCalled Set-NovaModuleVersion -Times 1 -ParameterFilter {
                $ProjectInfo.ProjectName -eq 'NovaModuleTools' -and
                        $Label -eq 'Minor' -and
                        $PreviewRelease -and
                        -not $Confirm
            }
        }
    }

    It 'Update-NovaModuleVersion delegates orchestration to private bump workflow helpers' {
        InModuleScope $script:moduleName {
            Mock Get-NovaVersionUpdateWorkflowContext {
                [pscustomobject]@{
                    Target = 'project.json'
                    Action = 'Update module version using Minor release label'
                }
            }
            Mock Invoke-NovaVersionUpdateWorkflow {
                [pscustomobject]@{NewVersion = '1.1.0'}
            }

            $result = Update-NovaModuleVersion -Path (Get-Location).Path -Confirm:$false

            $result.NewVersion | Should -Be '1.1.0'
            Assert-MockCalled Get-NovaVersionUpdateWorkflowContext -Times 1
            Assert-MockCalled Invoke-NovaVersionUpdateWorkflow -Times 1 -ParameterFilter {
                $WorkflowContext.Target -eq 'project.json' -and
                        $ShouldRun -and
                        -not $WhatIfEnabled
            }
        }
    }

    It 'Update-NovaModuleVersion re-invokes the CI-activated command before preparing the workflow when activation is needed' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Resolve-Path {[pscustomobject]@{Path = '/tmp/current-project'}} -ParameterFilter {$LiteralPath -eq '/tmp/current-project'}
            Mock Get-NovaVersionUpdateCiActivatedCommand {
                $script:steps += 'activate'
                {
                    param([string]$Path, [switch]$Preview, [switch]$ContinuousIntegration)

                    $script:steps += ('reinvoke:{0}:{1}:{2}' -f $Path, [bool]$Preview, [bool]$ContinuousIntegration)
                    [pscustomobject]@{NewVersion = '1.1.0'}
                }
            }
            Mock Get-NovaVersionUpdateWorkflowContext {throw 'should not continue in the stale module scope'}
            Mock Invoke-NovaVersionUpdateWorkflow {throw 'should not run the stale workflow'}

            $result = Update-NovaModuleVersion -Path '/tmp/current-project' -Preview -ContinuousIntegration -Confirm:$false

            $result.NewVersion | Should -Be '1.1.0'
            $script:steps | Should -Be @('activate', 'reinvoke:/tmp/current-project:True:True')
            Assert-MockCalled Get-NovaVersionUpdateCiActivatedCommand -Times 1 -ParameterFilter {$ProjectRoot -eq '/tmp/current-project'}
        }
    }

    It 'Update-NovaModuleVersion prepares the workflow directly in CI mode when activation is already satisfied' {
        InModuleScope $script:moduleName {
            Mock Resolve-Path {[pscustomobject]@{Path = '/tmp/current-project'}} -ParameterFilter {$LiteralPath -eq '/tmp/current-project'}
            Mock Get-NovaVersionUpdateCiActivatedCommand {$null}
            Mock Get-NovaVersionUpdateWorkflowContext {
                [pscustomobject]@{
                    PreviousVersion = '1.0.0'
                    NewVersion = '1.1.0'
                    Target = 'project.json'
                    Action = 'Update module version using Minor release label'
                }
            }
            Mock Invoke-NovaVersionUpdateWorkflow {
                [pscustomobject]@{NewVersion = '1.1.0'}
            }

            $result = Update-NovaModuleVersion -Path '/tmp/current-project' -ContinuousIntegration -Confirm:$false

            $result.NewVersion | Should -Be '1.1.0'
            Assert-MockCalled Get-NovaVersionUpdateCiActivatedCommand -Times 1 -ParameterFilter {$ProjectRoot -eq '/tmp/current-project'}
            Assert-MockCalled Get-NovaVersionUpdateWorkflowContext -Times 1 -ParameterFilter {$ProjectRoot -eq '/tmp/current-project' -and $ContinuousIntegrationRequested}
        }
    }

    It 'Update-NovaModuleVersion defaults Path to the current location when Path is omitted' {
        Invoke-UpdateNovaModuleVersionDefaultPathAssertion -ModuleName $script:moduleName
    }

    It 'Update-NovaModuleVersion -WhatIf stays side-effect free in CI mode' {
        InModuleScope $script:moduleName {
            Mock Resolve-Path {[pscustomobject]@{Path = '/tmp/current-project'}} -ParameterFilter {$LiteralPath -eq '/tmp/current-project'}
            Mock Get-NovaVersionUpdateCiActivatedCommand {throw 'should not activate during WhatIf'}
            Mock Get-NovaVersionUpdateWorkflowContext {
                [pscustomobject]@{
                    PreviousVersion = '1.0.0'
                    NewVersion = '1.1.0'
                    Label = 'Minor'
                    CommitCount = 1
                    Target = 'project.json'
                    Action = 'Update module version using Minor release label'
                }
            }
            Mock Invoke-NovaVersionUpdateWorkflow {
                [pscustomobject]@{NewVersion = '1.1.0'}
            }

            $result = Update-NovaModuleVersion -Path '/tmp/current-project' -ContinuousIntegration -WhatIf

            $result.NewVersion | Should -Be '1.1.0'
            Assert-MockCalled Get-NovaVersionUpdateCiActivatedCommand -Times 0
            Assert-MockCalled Get-NovaVersionUpdateWorkflowContext -Times 1 -ParameterFilter {$ContinuousIntegrationRequested}
        }
    }

    It 'Update-NovaModuleVersion -WhatIf returns the expected next version without persisting it when <Name>' -ForEach @(
        @{Name = 'the default bump flow is used'; CurrentVersion = '1.0.0'; CommitMessages = @('feat: add change'); Label = 'Minor'; NewVersion = '1.1.0'; Preview = $false}
        @{Name = 'preview mode starts from a stable version'; CurrentVersion = '1.5.3'; CommitMessages = @('feat: add change'); Label = 'Minor'; NewVersion = '1.6.0-preview'; Preview = $true}
        @{Name = 'preview mode zero-pads compact preview labels for gallery ordering'; CurrentVersion = '1.5.3-preview'; CommitMessages = @('fix: patch bug'); Label = 'Patch'; NewVersion = '1.5.3-preview01'; Preview = $true}
        @{Name = 'preview mode starts any bare prerelease stem at 01'; CurrentVersion = '1.5.3-SNAPSHOT'; CommitMessages = @('feat!: breaking api'); Label = 'Major'; NewVersion = '1.5.3-SNAPSHOT01'; Preview = $true}
        @{Name = 'preview mode continues an existing prerelease version'; CurrentVersion = '1.5.3-rc1'; CommitMessages = @('feat!: breaking api'); Label = 'Major'; NewVersion = '1.5.3-rc2'; Preview = $true}
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Version = $TestCase.CurrentVersion
                    ProjectJSON = '/tmp/project.json'
                }
            }
            Mock Get-GitCommitMessageForVersionBump {$TestCase.CommitMessages}
            Mock Get-VersionLabelFromCommitSet {$TestCase.Label}
            Mock Get-NovaVersionUpdatePlan {
                [pscustomobject]@{
                    ProjectFile = '/tmp/project.json'
                    CurrentVersion = [semver]$TestCase.CurrentVersion
                    NewVersion = [semver]$TestCase.NewVersion
                }
            }
            Mock Set-NovaModuleVersion {}

            $parameters = @{Path = (Get-Location).Path; WhatIf = $true}
            if ($TestCase.Preview) {
                $parameters.Preview = $true
            }

            $result = Update-NovaModuleVersion @parameters

            $result.PreviousVersion | Should -Be $TestCase.CurrentVersion
            $result.NewVersion | Should -Be $TestCase.NewVersion
            $result.Label | Should -Be $TestCase.Label
            Assert-MockCalled Get-NovaVersionUpdatePlan -Times 1 -ParameterFilter {$Label -eq $TestCase.Label}
            Assert-MockCalled Get-NovaVersionUpdatePlan -Times 1 -ParameterFilter {
                $Label -eq $TestCase.Label -and
                        ([bool]$PreviewRelease) -eq ([bool]$TestCase.Preview)
            }

            Assert-MockCalled Set-NovaModuleVersion -Times 0
        }
    }

    It 'Update-NovaModuleVersion -WhatIf finalizes a prerelease major target instead of carrying the old prerelease label forward' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Version = '2.0.0-preview7'
                    ProjectJSON = '/tmp/project.json'
                }
            }
            Mock Get-Content {'{"Version":"2.0.0-preview7"}'} -ParameterFilter {$LiteralPath -eq '/tmp/project.json' -and $Raw}
            Mock Get-GitCommitMessageForVersionBump {@('feat!: breaking api')}
            Mock Get-VersionLabelFromCommitSet {'Major'}
            Mock Set-NovaModuleVersion {}

            $result = Update-NovaModuleVersion -Path (Get-Location).Path -WhatIf

            $result.PreviousVersion | Should -Be '2.0.0-preview7'
            $result.NewVersion | Should -Be '2.0.0'
            $result.Label | Should -Be 'Major'
            Assert-MockCalled Set-NovaModuleVersion -Times 0
        }
    }

    It 'Update-NovaModuleVersion preserves nested package repository objects when writing the bumped version' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'package-repository-bump-project'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
            $projectJsonPath = Join-Path $projectRoot 'project.json'
            Set-Content -LiteralPath $projectJsonPath -Encoding utf8 -Value @'
{
  "ProjectName": "AzureDevOpsAgentInstaller",
  "Description": "Self-contained installer that configures Azure DevOps build agents on Windows.",
  "Version": "1.5.2-preview",
  "Manifest": {
    "Author": "DevOps Teamet"
  },
  "Package": {
    "RepositoryUrl": "https://packages.example/raw/",
    "Auth": {
      "HeaderName": "Authorization",
      "Scheme": "Basic",
      "Token": "NEXUS_TOKEN"
    },
    "Repositories": [
      {
        "Name": "staging",
        "Url": "https://packages.example/raw/staging/",
        "Auth": {
          "TokenEnvironmentVariable": "NEXUS_STAGING_TOKEN"
        }
      }
    ]
  }
}
'@
            Mock Get-GitCommitMessageForVersionBump {@('feat!: breaking api')}
            Mock Write-Host {}
            $warningMessages = $null

            $result = Update-NovaModuleVersion -Path $projectRoot -Confirm:$false -WarningVariable warningMessages
            $updatedProject = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json

            $result.PreviousVersion | Should -Be '1.5.2-preview'
            $result.NewVersion | Should -Be '2.0.0'
            $result.Label | Should -Be 'Major'
            $updatedProject.Version | Should -Be '2.0.0'
            ($updatedProject.Package.Repositories[0] -is [string]) | Should -BeFalse
            $updatedProject.Package.Repositories[0].Name | Should -Be 'staging'
            $updatedProject.Package.Repositories[0].Auth.TokenEnvironmentVariable | Should -Be 'NEXUS_STAGING_TOKEN'
            $warningMessages | Should -BeNullOrEmpty
        }
    }

    It 'Update-NovaModuleVersion -WhatIf falls back to a Patch preview when the project is not a git repository' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'no-git-bump-project'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Version = '1.0.0'
                    ProjectJSON = (Join-Path $projectRoot 'project.json')
                }
            }
            Mock Get-NovaVersionUpdatePlan {
                [pscustomobject]@{
                    ProjectFile = (Join-Path $projectRoot 'project.json')
                    CurrentVersion = [semver]'1.0.0'
                    NewVersion = [semver]'1.0.1'
                }
            }
            Mock Set-NovaModuleVersion {}

            $result = Update-NovaModuleVersion -Path $projectRoot -WhatIf

            $result.PreviousVersion | Should -Be '1.0.0'
            $result.NewVersion | Should -Be '1.0.1'
            $result.Label | Should -Be 'Patch'
            $result.CommitCount | Should -Be 0
            Assert-MockCalled Set-NovaModuleVersion -Times 0
        }
    }

    It 'Update-NovaModuleVersion -WhatIf throws a clear error when the repository has no commits yet' -Skip:(-not [bool](Get-Command git -ErrorAction SilentlyContinue)) {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'empty-git-bump-project'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
            & git -C $projectRoot init --quiet | Out-Null
            & git -C $projectRoot config user.name 'NovaModuleTools Tests' | Out-Null
            & git -C $projectRoot config user.email 'tests@example.invalid' | Out-Null

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Version = '1.0.0'
                    ProjectJSON = (Join-Path $projectRoot 'project.json')
                }
            }
            Mock Get-NovaVersionUpdatePlan {throw 'should not calculate a version plan'}
            Mock Set-NovaModuleVersion {throw 'should not write project.json'}

            $thrown = $null
            try {
                Update-NovaModuleVersion -Path $projectRoot -WhatIf
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Cannot bump version because the repository has no commits yet. Create an initial commit first.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Workflow.GitRepositoryHasNoCommits'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidOperation)
            $thrown.TargetObject | Should -Be $projectRoot

            Assert-MockCalled Get-NovaVersionUpdatePlan -Times 0
            Assert-MockCalled Set-NovaModuleVersion -Times 0
        }
    }

    It 'Update-NovaModuleVersion keeps native PowerShell Confirm support for direct cmdlet usage and does not route through the CLI helper' {
        InModuleScope $script:moduleName {
            $command = Get-Command -Name 'Update-NovaModuleVersion' -CommandType Function -ErrorAction Stop

            Mock Confirm-NovaCliCommandAction {throw 'direct PowerShell bump should not use the CLI confirmation helper'}
            Mock Get-NovaVersionUpdateWorkflowContext {
                [pscustomobject]@{
                    Target = 'project.json'
                    Action = 'Update module version using Minor release label'
                }
            }
            Mock Invoke-NovaVersionUpdateWorkflow {
                [pscustomobject]@{NewVersion = '1.1.0'}
            }

            $result = Update-NovaModuleVersion -Path (Get-Location).Path -Confirm:$false

            $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
            $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $result.NewVersion | Should -Be '1.1.0'
            Assert-MockCalled Confirm-NovaCliCommandAction -Times 0
        }
    }

    It 'Invoke-NovaCli bump uses the shared CLI confirmation wrapper for <Name> without forwarding raw Confirm' -ForEach @(
        @{Name = '--confirm'; Arguments = @('bump', '--confirm')}
        @{Name = '-c'; Arguments = @('bump', '-c')}
    ) {
        InModuleScope $script:moduleName -Parameters @{Arguments = $_.Arguments} {
            param($Arguments)

            Mock Confirm-NovaCliCommandAction {}
            Mock Update-NovaModuleVersion {
                param([switch]$Preview, [switch]$WhatIf, [bool]$Confirm)

                [pscustomobject]@{
                    Preview = $Preview.IsPresent
                    WhatIf = $WhatIf.IsPresent
                    Confirm = $Confirm
                }
            }

            $result = Invoke-NovaCli @Arguments

            $result.Preview | Should -BeFalse
            $result.WhatIf | Should -BeFalse
            $result.Confirm | Should -BeFalse
            Assert-MockCalled Confirm-NovaCliCommandAction -Times 1 -ParameterFilter {$Command -eq 'bump'}
        }
    }

    It 'Confirm-NovaCliCommandAction accepts Enter as the default confirmation response' {
        Invoke-ConfirmNovaCliCommandActionEnterAssertion -ModuleName $script:moduleName
    }

    It 'Confirm-NovaCliCommandAction retries after invalid input and returns after an accepted response' {
        Invoke-ConfirmNovaCliCommandActionRetryAssertion -ModuleName $script:moduleName
    }

    It 'Confirm-NovaCliCommandAction stops the operation with the expected CLI cancellation result for No' {
        Invoke-ConfirmNovaCliCommandActionCancellationAssertion -ModuleName $script:moduleName -TestCase @{
            Key = 'N'
            ExpectedMessage = 'Operation cancelled.'
            ExpectedErrorId = 'Nova.Workflow.CliOperationCancelled'
        }
    }

    It 'Confirm-NovaCliCommandAction stops the operation with the expected CLI cancellation result for Suspend' {
        Invoke-ConfirmNovaCliCommandActionCancellationAssertion -ModuleName $script:moduleName -TestCase @{
            Key = 'S'
            ExpectedMessage = 'Suspend is not supported in nova CLI mode. Operation cancelled.'
            ExpectedErrorId = 'Nova.Workflow.CliSuspendNotSupported'
        }
    }
}
