function global:Get-TestSupportPath {
    [CmdletBinding()]
    param()

    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
}

function global:Get-TestSupportFunctionNameList {
    [CmdletBinding()]
    param()

    return @(
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
    )
}

function global:Import-TestSupportFunctions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SupportPath,
        [Parameter(Mandatory)][string[]]$FunctionNameList
    )

    . $SupportPath
    Publish-TestSupportFunctions -FunctionNameList $FunctionNameList
}

function global:Initialize-TestSupportEnvironment {
    [CmdletBinding()]
    param()

    $script:testSupportPath = Get-TestSupportPath
    $global:novaCommandModelTestSupportFunctionNameList = Get-TestSupportFunctionNameList
    Import-TestSupportFunctions -SupportPath $script:testSupportPath -FunctionNameList $global:novaCommandModelTestSupportFunctionNameList
}

Initialize-TestSupportEnvironment

BeforeAll {
    $testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
    . $testSupportPath
    $script:assertTestNovaCliConfirmDecisions = (Get-Command -Name 'Assert-TestNovaCliConfirmDecisions' -CommandType Function -ErrorAction Stop).ScriptBlock
    $script:invokeReadNovaCliPromptKeyAssertion = (Get-Command -Name 'Invoke-ReadNovaCliPromptKeyAssertion' -CommandType Function -ErrorAction Stop).ScriptBlock
    $script:invokeGetNovaCliCommandPromptKeyAssertion = (Get-Command -Name 'Invoke-GetNovaCliCommandPromptKeyAssertion' -CommandType Function -ErrorAction Stop).ScriptBlock
    $script:invokeGetNovaCliCommandCancellationInfoAssertion = (Get-Command -Name 'Invoke-GetNovaCliCommandCancellationInfoAssertion' -CommandType Function -ErrorAction Stop).ScriptBlock
    $script:invokeUpdateNovaModuleVersionDefaultPathAssertion = (Get-Command -Name 'Invoke-UpdateNovaModuleVersionDefaultPathAssertion' -CommandType Function -ErrorAction Stop).ScriptBlock
    $script:invokeConfirmNovaCliCommandActionEnterAssertion = (Get-Command -Name 'Invoke-ConfirmNovaCliCommandActionEnterAssertion' -CommandType Function -ErrorAction Stop).ScriptBlock
    $script:invokeConfirmNovaCliCommandActionRetryAssertion = (Get-Command -Name 'Invoke-ConfirmNovaCliCommandActionRetryAssertion' -CommandType Function -ErrorAction Stop).ScriptBlock
    $script:invokeConfirmNovaCliCommandActionCancellationAssertion = (Get-Command -Name 'Invoke-ConfirmNovaCliCommandActionCancellationAssertion' -CommandType Function -ErrorAction Stop).ScriptBlock
    Publish-TestSupportFunctions -FunctionNameList $global:novaCommandModelTestSupportFunctionNameList
    $moduleContext = Initialize-TestModuleContext -CommandPath $PSCommandPath -SupportPath $testSupportPath -FunctionNameList $global:novaCommandModelTestSupportFunctionNameList
    $script:moduleName = $moduleContext.ModuleName
    $script:distModuleDir = $moduleContext.DistModuleDir
}

Describe 'Nova command model - bump and CLI confirmation behavior' {
    It 'Get-NovaCliConfirmDecision approves Yes and Yes to All, and cancels No, No to All, and Suspend' {
        & $script:assertTestNovaCliConfirmDecisions -ModuleName $script:moduleName
    }

    It 'Read-NovaCliPromptKey returns the expected result when console input <Name>' -ForEach @(
        @{Name = 'is available'; Expected = [char]'y'; ConsoleKeyChar = [char]'y'; Throws = $false}
        @{Name = 'fails'; Expected = [char]0; ConsoleKeyChar = [char]0; Throws = $true}
    ) {
        & $script:invokeReadNovaCliPromptKeyAssertion -ModuleName $script:moduleName -TestCase $_
    }

    It 'Get-NovaCliCommandPromptKey returns the expected key when prompt input <Name>' -ForEach @(
        @{Name = 'uses the NOVA_CLI_CONFIRM_RESPONSE override'; EnvironmentResponse = 'later'; Expected = [char]'l'; PromptReadCount = 0}
        @{Name = 'must be read from the interactive prompt'; EnvironmentResponse = ''; Expected = [char]'n'; PromptReadCount = 1}
    ) {
        & $script:invokeGetNovaCliCommandPromptKeyAssertion -ModuleName $script:moduleName -TestCase $_
    }

    It 'Get-NovaCliCommandCancellationInfo returns the expected cancellation metadata for <Name>' -ForEach @(
        @{Name = 'Suspend'; Key = 'S'; ExpectedMessage = 'Suspend is not supported in nova CLI mode. Operation cancelled.'; ExpectedErrorId = 'Nova.Workflow.CliSuspendNotSupported'}
        @{Name = 'No'; Key = 'N'; ExpectedMessage = 'Operation cancelled.'; ExpectedErrorId = 'Nova.Workflow.CliOperationCancelled'}
    ) {
        & $script:invokeGetNovaCliCommandCancellationInfoAssertion -ModuleName $script:moduleName -TestCase $_
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
            Assert-MockCalled Get-NovaVersionUpdatePlan -Times 1 -ParameterFilter {
                $ProjectInfo.ProjectName -eq 'NovaModuleTools' -and
                        $Label -eq 'Minor' -and
                        -not $PreviewRelease
            }
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

    It 'Update-NovaModuleVersion defaults Path to the current location when Path is omitted' {
        & $script:invokeUpdateNovaModuleVersionDefaultPathAssertion -ModuleName $script:moduleName
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
        & $script:invokeConfirmNovaCliCommandActionEnterAssertion -ModuleName $script:moduleName
    }

    It 'Confirm-NovaCliCommandAction retries after invalid input and returns after an accepted response' {
        & $script:invokeConfirmNovaCliCommandActionRetryAssertion -ModuleName $script:moduleName
    }

    It 'Confirm-NovaCliCommandAction stops the operation with the expected CLI cancellation result for No' {
        & $script:invokeConfirmNovaCliCommandActionCancellationAssertion -ModuleName $script:moduleName -TestCase @{
            Key = 'N'
            ExpectedMessage = 'Operation cancelled.'
            ExpectedErrorId = 'Nova.Workflow.CliOperationCancelled'
        }
    }

    It 'Confirm-NovaCliCommandAction stops the operation with the expected CLI cancellation result for Suspend' {
        & $script:invokeConfirmNovaCliCommandActionCancellationAssertion -ModuleName $script:moduleName -TestCase @{
            Key = 'S'
            ExpectedMessage = 'Suspend is not supported in nova CLI mode. Operation cancelled.'
            ExpectedErrorId = 'Nova.Workflow.CliSuspendNotSupported'
        }
    }
}
