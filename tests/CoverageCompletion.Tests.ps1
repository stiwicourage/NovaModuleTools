$script:coverageCompletionTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'CoverageCompletion.TestSupport.ps1')).Path
$global:coverageCompletionTestSupportFunctionNameList = @(
    'New-TestPromptHostUi'
    'New-TestChoiceHostUi'
)
. $script:coverageCompletionTestSupportPath

foreach ($functionName in $global:coverageCompletionTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $coverageCompletionTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'CoverageCompletion.TestSupport.ps1')).Path
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    . $coverageCompletionTestSupportPath
    foreach ($functionName in $global:coverageCompletionTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Coverage completion for remaining low-coverage helpers' {
    It 'Test-ProjectSchema validates the Pester schema' {
        InModuleScope $script:moduleName {
            Mock Get-ResourceFilePath {
                if ($FileName -eq 'Schema-Build.json') {
                    return '/tmp/build-schema.json'
                }

                return '/tmp/pester-schema.json'
            }
            Mock Get-Content {
                if ($Path -eq '/tmp/pester-schema.json') {
                    return '{"title":"pester"}'
                }

                return '{"title":"build"}'
            }
            Mock Test-Json {$true}

            Test-ProjectSchema -Schema Pester | Should -BeTrue

            Assert-MockCalled Test-Json -Times 1 -ParameterFilter {
                $Path -eq 'project.json' -and $Schema -eq '{"title":"pester"}'
            }
        }
    }

    It 'Get-LocalModulePathPattern and Get-LocalModulePathErrorMessage return the current platform defaults' {
        InModuleScope $script:moduleName {
            $pattern = Get-LocalModulePathPattern
            $message = Get-LocalModulePathErrorMessage -MatchPattern $pattern

            if ($IsWindows) {
                $pattern | Should -Be '\\Documents\\PowerShell\\Modules'
                $message | Should -Be "No windows module path matching $pattern found"
            }
            else {
                $pattern | Should -Be '/\.local/share/powershell/Modules$'
                $message | Should -Be "No macOS/Linux module path matching $pattern found in PSModulePath."
            }
        }
    }

    It 'Get-LocalModulePathPattern and Get-LocalModulePathErrorMessage support the opposite platform branch' {
        $targetIsWindows = -not [bool]$IsWindows

        InModuleScope $script:moduleName -Parameters @{TargetIsWindows = $targetIsWindows} {
            param($TargetIsWindows)

            try {
                Set-Variable -Name IsWindows -Value $TargetIsWindows -Force

                $pattern = Get-LocalModulePathPattern
                $message = Get-LocalModulePathErrorMessage -MatchPattern $pattern

                if ($TargetIsWindows) {
                    $pattern | Should -Be ([regex]::Escape('\Documents\PowerShell\Modules'))
                    $message | Should -Be "No windows module path matching $pattern found"
                }
                else {
                    $pattern | Should -Be '/\.local/share/powershell/Modules$'
                    $message | Should -Be "No macOS/Linux module path matching $pattern found in PSModulePath."
                }
            }
            finally {
                Remove-Variable -Name IsWindows -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Get-AwesomeHostUi returns the current host UI instance type' {
        $expectedType = $Host.UI.GetType().FullName

        InModuleScope $script:moduleName -Parameters @{ExpectedType = $expectedType} {
            param($ExpectedType)

            $result = Get-AwesomeHostUi

            $result | Should -Not -BeNullOrEmpty
            $result.GetType().FullName | Should -Be $ExpectedType
        }
    }

    It 'Read-AwesomeHost handles standard prompt case <Name>' -ForEach @(
        @{
            Name = 'entered text'
            Caption = 'Module Name'
            Message = 'Enter module name'
            Prompt = 'Name'
            Default = 'ignored'
            Responses = @('NovaModuleTools')
            Expected = 'NovaModuleTools'
            ExpectedPromptCalls = 1
        }
        @{
            Name = 'mandatory retry'
            Caption = 'Module Name'
            Message = 'Enter module name'
            Prompt = 'Name'
            Default = 'MANDATORY'
            Responses = @($null, 'NovaModuleTools')
            Expected = 'NovaModuleTools'
            ExpectedPromptCalls = 2
        }
        @{
            Name = 'default fallback'
            Caption = 'Semantic Version'
            Message = 'Starting version'
            Prompt = 'Version'
            Default = '0.0.1'
            Responses = @('')
            Expected = '0.0.1'
            ExpectedPromptCalls = 1
        }
    ) {
        $hostUi = New-TestPromptHostUi {
            param($CallCount)

            return [pscustomobject]@{Values = $Responses[$CallCount - 1]}
        }

        $result = InModuleScope $script:moduleName -Parameters @{HostUi = $hostUi; PromptCase = $_} {
            param($HostUi, $PromptCase)

            Mock Get-AwesomeHostUi {$HostUi}

            Read-AwesomeHost -Ask ([pscustomobject]@{
                Caption = $PromptCase.Caption
                Message = $PromptCase.Message
                Prompt = $PromptCase.Prompt
                Default = $PromptCase.Default
                Choice = $null
            })
        }

        $result | Should -Be $Expected
        $hostUi.State.PromptCalls | Should -Be $ExpectedPromptCalls
        $hostUi.State.Caption | Should -Be $Caption
        $hostUi.State.Message | Should -Be $Message
        $hostUi.State.FieldDescriptions.Count | Should -Be 1
        $hostUi.State.FieldDescriptions[0].Name | Should -Be $Prompt

        if ($Default -eq 'MANDATORY') {
            $hostUi.State.FieldDescriptions[0].DefaultValue | Should -BeNullOrEmpty
        }
        else {
            $hostUi.State.FieldDescriptions[0].DefaultValue | Should -Be $Default
        }
    }

    It 'Read-AwesomeHost returns the selected label for choice prompts' {
        $hostUi = New-TestChoiceHostUi -ChoiceIndex 0

        $result = InModuleScope $script:moduleName -Parameters @{HostUi = $hostUi} {
            param($HostUi)

            Mock Get-AwesomeHostUi {$HostUi}

            Read-AwesomeHost -Ask ([pscustomobject]@{
                Caption = 'Git Version Control'
                Message = 'Enable git?'
                Default = 'No'
                Choice = [ordered]@{
                    Yes = 'Enable Git'
                    No = 'Skip Git initialization'
                }
            })
        }

        $result | Should -Be 'Yes'
        $hostUi.State.ChoiceCalls | Should -Be 1
        $hostUi.State.DefaultChoiceIndex | Should -Be 1
        $hostUi.State.ChoiceLabels | Should -Be @('&Yes', '&No')
    }

    It 'Read-AwesomeHost uses choice prompts for hashtable-based scaffold questions' {
        $hostUi = New-TestChoiceHostUi -ChoiceIndex 1

        $result = InModuleScope $script:moduleName -Parameters @{HostUi = $hostUi} {
            param($HostUi)

            Mock Get-AwesomeHostUi {$HostUi}

            Read-AwesomeHost -Ask @{
                Caption = 'Pester Testing'
                Message = 'Do you want to enable basic Pester Testing'
                Prompt = 'EnablePester'
                Default = 'No'
                Choice = [ordered]@{
                    Yes = 'Enable pester to perform testing'
                    No = 'Skip pester testing'
                }
            }
        }

        $result | Should -Be 'No'
        $hostUi.State.ChoiceCalls | Should -Be 1
        $hostUi.State.DefaultChoiceIndex | Should -Be 1
        $hostUi.State.ChoiceLabels | Should -Be @('&Yes', '&No')
    }

    It 'Read-AwesomeHost treats prompts without a Choice property as standard prompts' {
        $hostUi = New-TestPromptHostUi {
            [pscustomobject]@{Values = 'NovaModuleTools'}
        }

        $result = InModuleScope $script:moduleName -Parameters @{HostUi = $hostUi} {
            param($HostUi)

            Mock Get-AwesomeHostUi {$HostUi}

            Read-AwesomeHost -Ask ([pscustomobject]@{
                Caption = 'Module Name'
                Message = 'Enter module name'
                Prompt = @{}
                Default = 'MANDATORY'
            })
        }

        $result | Should -Be 'NovaModuleTools'
        $hostUi.State.PromptCalls | Should -Be 1
    }

    It 'Get-FunctionSourceIndex adds entries for indexable files' {
        InModuleScope $script:moduleName {
            $sourceFile = Get-Item -LiteralPath (Join-Path $TestDrive 'Example.ps1') -ErrorAction SilentlyContinue
            if (-not $sourceFile) {
                Set-Content -LiteralPath (Join-Path $TestDrive 'Example.ps1') -Value 'function Get-Example { }'
                $sourceFile = Get-Item -LiteralPath (Join-Path $TestDrive 'Example.ps1')
            }

            Mock Get-IndexableSourceFile {@($File)}
            Mock Add-FunctionSourceIndexEntryFromFile {
                $Index['Get-Example'] = @([pscustomobject]@{Path = $File.FullName; Line = 1})
            }

            $index = Get-FunctionSourceIndex -File $sourceFile

            $index['Get-Example'][0].Line | Should -Be 1
            $index['Get-Example'][0].Path | Should -Be $sourceFile.FullName
        }
    }

    It 'Assert-BuiltModuleHasNoDuplicateFunctionName throws when the built module file is missing' {
        InModuleScope $script:moduleName {
            Mock Test-Path {$false}

            {
                Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo ([pscustomobject]@{ModuleFilePSM1 = '/tmp/missing.psm1'})
            } | Should -Throw 'Built module file not found*'
        }
    }

    It 'Assert-BuiltModuleHasNoDuplicateFunctionName throws when the built module has parse errors' {
        InModuleScope $script:moduleName {
            Mock Test-Path {$true}
            Mock Get-PowerShellAstFromFile {
                [pscustomobject]@{
                    Errors = @([pscustomobject]@{Message = 'unexpected token'})
                    Ast = $null
                }
            }

            {
                Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo ([pscustomobject]@{ModuleFilePSM1 = '/tmp/bad.psm1'})
            } | Should -Throw 'Built module contains parse errors*unexpected token'
        }
    }

    It 'Assert-BuiltModuleHasNoDuplicateFunctionName throws when the built module has no top-level functions' {
        InModuleScope $script:moduleName {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput('Set-StrictMode -Version Latest', [ref]$tokens, [ref]$errors)

            Mock Test-Path {$true}
            Mock Get-PowerShellAstFromFile {
                [pscustomobject]@{
                    Errors = @()
                    Ast = $ast
                }
            }
            Mock Get-DuplicateFunctionGroup {}

            {
                Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo ([pscustomobject]@{ModuleFilePSM1 = '/tmp/empty.psm1'})
            } | Should -Throw 'No functions found to build. Add a function to the source file.'
            Assert-MockCalled Get-DuplicateFunctionGroup -Times 0
        }
    }

    It 'Publish-NovaBuiltModuleToDirectory creates the destination when it is missing' {
        InModuleScope $script:moduleName {
            Mock Test-Path {
                if ($LiteralPath -eq '/tmp/modules' -and $PathType -eq 'Container') {
                    return $false
                }

                return $false
            }
            Mock New-Item {[pscustomobject]@{FullName = $Path}}
            Mock Remove-Item {}
            Mock Copy-Item {}

            Publish-NovaBuiltModuleToDirectory -ProjectInfo ([pscustomobject]@{ProjectName = 'NovaModuleTools'; OutputModuleDir = '/tmp/dist'}) -ModuleDirectoryPath '/tmp/modules'

            Assert-MockCalled New-Item -Times 1 -ParameterFilter {$Path -eq '/tmp/modules' -and $ItemType -eq 'Directory' -and $Force}
            Assert-MockCalled Remove-Item -Times 0
            Assert-MockCalled Copy-Item -Times 1 -ParameterFilter {$Path -eq '/tmp/dist' -and $Destination -eq '/tmp/modules' -and $Recurse}
        }
    }

    It 'Publish-NovaBuiltModuleToDirectory removes an existing module copy before copying' {
        InModuleScope $script:moduleName {
            Mock Test-Path {
                if ($LiteralPath -eq '/tmp/modules' -and $PathType -eq 'Container') {
                    return $true
                }

                return $LiteralPath -eq '/tmp/modules/NovaModuleTools'
            }
            Mock New-Item {}
            Mock Remove-Item {}
            Mock Copy-Item {}

            Publish-NovaBuiltModuleToDirectory -ProjectInfo ([pscustomobject]@{ProjectName = 'NovaModuleTools'; OutputModuleDir = '/tmp/dist'}) -ModuleDirectoryPath '/tmp/modules'

            Assert-MockCalled New-Item -Times 0
            Assert-MockCalled Remove-Item -Times 1 -ParameterFilter {$LiteralPath -eq '/tmp/modules/NovaModuleTools' -and $Recurse -and $Force}
            Assert-MockCalled Copy-Item -Times 1 -ParameterFilter {$Path -eq '/tmp/dist' -and $Destination -eq '/tmp/modules' -and $Recurse}
        }
    }

    It 'Invoke-NovaRelease uses repository publishing when a repository is supplied' {
        InModuleScope $script:moduleName {
            $publishAction = {
                param($ProjectInfo, $Repository, $ApiKey)

                Publish-NovaBuiltModuleToRepository @PSBoundParameters
            }

            Mock Get-NovaProjectInfo {[pscustomobject]@{ProjectName = 'NovaModuleTools'; OutputModuleDir = '/tmp/dist'}}
            Mock Invoke-NovaBuild {}
            Mock Test-NovaBuild {}
            Mock Update-NovaModuleVersion {[pscustomobject]@{NewVersion = '2.0.0'}}
            Mock Publish-NovaBuiltModuleToRepository {}
            Mock Get-Command {[pscustomobject]@{ScriptBlock = $publishAction}} -ParameterFilter {$Name -eq 'Publish-NovaBuiltModuleToRepository' -and $CommandType -eq 'Function'}

            $result = Invoke-NovaRelease -PublishOption @{Repository = 'PSGallery'; ApiKey = 'repo-key'} -Path (Get-Location).Path

            $result.NewVersion | Should -Be '2.0.0'
            Assert-MockCalled Publish-NovaBuiltModuleToRepository -Times 1 -ParameterFilter {$Repository -eq 'PSGallery' -and $ApiKey -eq 'repo-key'}
        }
    }

    It 'Update-NovaModuleVersion updates the version when the change is approved' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'project-root'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{Version = '1.2.3'; ProjectJSON = (Join-Path $projectRoot 'project.json')}
            }
            Mock Get-GitCommitMessageForVersionBump {@('fix: patch bug')}
            Mock Get-VersionLabelFromCommitSet {'Patch'}
            Mock Get-NovaVersionUpdatePlan {
                [pscustomobject]@{
                    ProjectFile = (Join-Path $projectRoot 'project.json')
                    CurrentVersion = [semver]'1.2.3'
                    NewVersion = [semver]'1.2.4'
                }
            }
            Mock Set-NovaModuleVersion {}

            $result = Update-NovaModuleVersion -Path $projectRoot -Confirm:$false

            $result.PreviousVersion | Should -Be '1.2.3'
            $result.NewVersion | Should -Be '1.2.4'
            $result.Label | Should -Be 'Patch'
            $result.CommitCount | Should -Be 1
            Assert-MockCalled Set-NovaModuleVersion -Times 1 -ParameterFilter {$Label -eq 'Patch' -and $Confirm -eq $false}
        }
    }

    It 'New-InitiateGitRepo warns when git is unavailable' {
        InModuleScope $script:moduleName {
            Mock Get-Command {$null} -ParameterFilter {$Name -eq 'git'}
            Mock Write-Warning {}

            New-InitiateGitRepo -DirectoryPath $TestDrive -Confirm:$false

            Assert-MockCalled Write-Warning -Times 1 -ParameterFilter {$Message -like 'Git is not installed*'}
        }
    }

    It 'New-InitiateGitRepo initializes a git repository when git is available' {
        InModuleScope $script:moduleName {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'git is not available in this environment'
                return
            }

            $repoPath = Join-Path $TestDrive 'git-init'
            New-Item -ItemType Directory -Path $repoPath -Force | Out-Null

            New-InitiateGitRepo -DirectoryPath $repoPath -Confirm:$false

            Test-Path -LiteralPath (Join-Path $repoPath '.git') | Should -BeTrue
        }
    }
}






