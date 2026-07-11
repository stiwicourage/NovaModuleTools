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

        Should -Invoke Initialize-NovaModuleScaffold -Times 1
        Should -Invoke Write-NovaModuleProjectJson -Times 1
        Should -Invoke Write-NovaVsCodeSettings -Times 1 -ParameterFilter {$ProjectRoot -eq '/tmp/DemoModule'}
        Should -Invoke Initialize-NovaModuleAgenticCopilotScaffold -Times 0
        Should -Invoke Write-Progress -Times 4
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Creating scaffold files' -and $PercentComplete -eq 25
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Writing project.json' -and $PercentComplete -eq 60
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Writing VS Code settings' -and $PercentComplete -eq 75
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        Should -Invoke Write-Message -Times 4
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $InputObject -eq 'Created Nova module scaffold: DemoModule' -and $color -eq 'Green'
        }
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
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

        Should -Invoke Initialize-NovaModuleAgenticCopilotScaffold -Times 1
        Should -Invoke Write-Progress -Times 5
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Applying Agentic Copilot starter' -and $PercentComplete -eq 85
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
    }

    It 'suggests unit and build-validation tests as the next steps for the example scaffold' {
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

        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        Should -Invoke Write-Message -Times 1 -ParameterFilter {$InputObject -eq 'Invoke-NovaTest'}
        Should -Invoke Write-Message -Times 1 -ParameterFilter {$InputObject -eq 'Test-NovaBuild'}
    }
}
