BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/InvokeNovaModuleInitializationWorkflow.ps1')

    . (Join-Path $PSScriptRoot 'InvokeNovaModuleInitializationWorkflow.TestSupport.ps1')
}

Describe 'Invoke-NovaModuleInitializationWorkflow' {
    BeforeAll {
        $script:context = [pscustomobject]@{
            AnswerSet = @{ProjectName = 'DemoModule'; EnableAgenticCopilot = 'No'}
            Layout = [pscustomobject]@{Project = '/tmp/DemoModule'; ProjectJsonFile = '/tmp/DemoModule/project.json'}
            Example = $false
        }
    }

    It 'initializes the scaffold and writes the project.json before announcing completion' {
        Mock Initialize-NovaModuleScaffold {}
        Mock Write-NovaModuleProjectJson {}
        Mock Initialize-NovaModuleAgenticCopilotScaffold {}
        Mock Write-Message {}

        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $script:context

        Assert-MockCalled Initialize-NovaModuleScaffold -Times 1
        Assert-MockCalled Write-NovaModuleProjectJson -Times 1
        Assert-MockCalled Initialize-NovaModuleAgenticCopilotScaffold -Times 0
        Assert-MockCalled Write-Message -Times 1
    }

    It 'invokes the Agentic Copilot scaffold step when the answer set requests it' {
        Mock Initialize-NovaModuleScaffold {}
        Mock Write-NovaModuleProjectJson {}
        Mock Initialize-NovaModuleAgenticCopilotScaffold {}
        Mock Write-Message {}

        $contextWithAgentic = [pscustomobject]@{
            AnswerSet = @{ProjectName = 'DemoModule'; EnableAgenticCopilot = 'Yes'}
            Layout = [pscustomobject]@{Project = '/tmp/DemoModule'; ProjectJsonFile = '/tmp/DemoModule/project.json'}
            Example = $false
        }
        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $contextWithAgentic

        Assert-MockCalled Initialize-NovaModuleAgenticCopilotScaffold -Times 1
    }
}
