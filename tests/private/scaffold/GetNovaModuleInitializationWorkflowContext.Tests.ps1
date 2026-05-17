BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Get-NovaModuleInitializationWorkflowContext' {
    It 'runs the update notification before collecting init answers' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Resolve-NovaModuleScaffoldBasePath {'/tmp/base'}
            Mock Get-NovaModuleQuestionSet {[ordered]@{ProjectName = @{Prompt = 'Name?'}}}
            Mock Invoke-NovaModuleUpdateNotificationSafely {$script:steps += 'notification'}
            Mock Read-NovaModuleAnswerSet {
                $script:steps += 'questions'
                [ordered]@{
                    ProjectName = 'NovaContext'
                    EnableGit = 'No'
                    EnableAgenticCopilot = 'No'
                }
            }
            Mock Get-NovaModuleScaffoldLayout {
                [pscustomobject]@{
                    Project = '/tmp/base/NovaContext'
                    ProjectJsonFile = '/tmp/base/NovaContext/project.json'
                }
            }

            $result = Get-NovaModuleInitializationWorkflowContext -Path '/tmp/base'

            $script:steps -join ',' | Should -Be 'notification,questions'
            $result.Target | Should -Be '/tmp/base/NovaContext'
            Assert-MockCalled Invoke-NovaModuleUpdateNotificationSafely -Times 1
            Assert-MockCalled Read-NovaModuleAnswerSet -Times 1
        }
    }
}

