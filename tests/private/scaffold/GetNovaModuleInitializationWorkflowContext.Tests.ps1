BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/GetNovaModuleInitializationWorkflowContext.ps1')

    function Resolve-NovaModuleScaffoldBasePath {param($Path)}
    function Get-NovaModuleQuestionSet {param([switch]$Example)}
    function Invoke-NovaModuleUpdateNotificationSafely {}
    function Read-NovaModuleAnswerSet {param($Questions)}
    function Get-NovaModuleScaffoldLayout {param($Path, $ProjectName)}
}

Describe 'Get-NovaModuleInitializationWorkflowContext' {
    It 'runs the update notification before collecting init answers' {
        $global:steps = @()
        try {
            Mock Resolve-NovaModuleScaffoldBasePath {'/tmp/base'}
            Mock Get-NovaModuleQuestionSet {[ordered]@{ProjectName = @{Prompt = 'Name?'}}}
            Mock Invoke-NovaModuleUpdateNotificationSafely {$global:steps += 'notification'}
            Mock Read-NovaModuleAnswerSet {
                $global:steps += 'questions'
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

            $global:steps -join ',' | Should -Be 'notification,questions'
            $result.Target | Should -Be '/tmp/base/NovaContext'
            Assert-MockCalled Invoke-NovaModuleUpdateNotificationSafely -Times 1
            Assert-MockCalled Read-NovaModuleAnswerSet -Times 1
        } finally {
            Remove-Variable -Name steps -Scope Global -ErrorAction SilentlyContinue
        }
    }
}
