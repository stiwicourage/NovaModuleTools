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
        Mock Write-NovaVsCodeSettings {}
        Mock Initialize-NovaModuleAgenticCopilotScaffold {}
        Mock Write-Message {}
        Mock Write-Progress {}

        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $script:context

        Assert-MockCalled Initialize-NovaModuleScaffold -Times 1
        Assert-MockCalled Write-NovaModuleProjectJson -Times 1
        Assert-MockCalled Write-NovaVsCodeSettings -Times 1 -ParameterFilter { $ProjectRoot -eq '/tmp/DemoModule' }
        Assert-MockCalled Initialize-NovaModuleAgenticCopilotScaffold -Times 0
        Assert-MockCalled Write-Progress -Times 4
        Assert-MockCalled Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Creating scaffold files' -and $PercentComplete -eq 25
        }
        Assert-MockCalled Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Writing project.json' -and $PercentComplete -eq 60
        }
        Assert-MockCalled Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Writing VS Code settings' -and $PercentComplete -eq 75
        }
        Assert-MockCalled Write-Progress -Times 1 -ParameterFilter {$Completed}
        Assert-MockCalled Write-Message -Times 4
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $InputObject -eq 'Created Nova module scaffold: DemoModule' -and $color -eq 'Green'
        }
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $InputObject -eq 'Invoke-NovaBuild'
        }
    }

    It 'invokes the Agentic Copilot scaffold step when the answer set requests it' {
        Mock Initialize-NovaModuleScaffold {}
        Mock Write-NovaModuleProjectJson {}
        Mock Write-NovaVsCodeSettings {}
        Mock Initialize-NovaModuleAgenticCopilotScaffold {}
        Mock Write-Message {}
        Mock Write-Progress {}

        $contextWithAgentic = [pscustomobject]@{
            AnswerSet = @{ProjectName = 'DemoModule'; EnableAgenticCopilot = 'Yes'}
            Layout = [pscustomobject]@{Project = '/tmp/DemoModule'; ProjectJsonFile = '/tmp/DemoModule/project.json'}
            Example = $false
        }
        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $contextWithAgentic

        Assert-MockCalled Initialize-NovaModuleAgenticCopilotScaffold -Times 1
        Assert-MockCalled Write-Progress -Times 5
        Assert-MockCalled Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Applying Agentic Copilot starter' -and $PercentComplete -eq 85
        }
        Assert-MockCalled Write-Progress -Times 1 -ParameterFilter {$Completed}
    }

    It 'suggests Test-NovaBuild as the next step for the example scaffold' {
        Mock Initialize-NovaModuleScaffold {}
        Mock Write-NovaModuleProjectJson {}
        Mock Write-NovaVsCodeSettings {}
        Mock Initialize-NovaModuleAgenticCopilotScaffold {}
        Mock Write-Message {}
        Mock Write-Progress {}

        $exampleContext = [pscustomobject]@{
            AnswerSet = @{ProjectName = 'DemoModule'; EnableAgenticCopilot = 'No'}
            Layout = [pscustomobject]@{Project = '/tmp/DemoModule'; ProjectJsonFile = '/tmp/DemoModule/project.json'}
            Example = $true
        }

        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $exampleContext

        Assert-MockCalled Write-Progress -Times 1 -ParameterFilter {$Completed}
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $InputObject -eq 'Test-NovaBuild'
        }
    }
}
