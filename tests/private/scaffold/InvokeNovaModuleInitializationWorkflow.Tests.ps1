BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/InvokeNovaModuleInitializationWorkflow.ps1')

    function Initialize-NovaModuleScaffold {param($Answer, $Paths, [switch]$Example)}
    function Write-NovaModuleProjectJson {param($Answer, [string]$ProjectJsonFile, [switch]$Example)}
    function Initialize-NovaModuleAgenticCopilotScaffold {param($Answer, [string]$ProjectRoot, [switch]$Example)}
    function Write-Message {param([Parameter(ValueFromPipeline = $true)]$InputObject, [string]$color)}
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
