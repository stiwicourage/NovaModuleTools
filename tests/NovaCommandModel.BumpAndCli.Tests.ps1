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
}

Describe 'Nova command model - bump and CLI confirmation behavior' {
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

    It 'Update-NovaModuleVersion -WhatIf throws a clear error when the repository has no commits yet' {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'git is not available in this environment'
            return
        }

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

            {Update-NovaModuleVersion -Path $projectRoot -WhatIf} | Should -Throw 'Cannot bump version because the repository has no commits yet. Create an initial commit first.'

            Assert-MockCalled Get-NovaVersionUpdatePlan -Times 0
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
}




