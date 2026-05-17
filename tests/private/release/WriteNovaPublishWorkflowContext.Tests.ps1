BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/WriteNovaPublishWorkflowContext.ps1')

    function Write-NovaLocalWorkflowMode {param($WorkflowName, [switch]$LocalRequested)}
    function Write-NovaResolvedLocalPublishTarget {param($PublishInvocation)}
}

Describe 'Write-NovaPublishWorkflowContext' {
    It 'delegates to the local mode and resolved target writers' {
        Mock Write-NovaLocalWorkflowMode {}
        Mock Write-NovaResolvedLocalPublishTarget {}
        $ctx = [pscustomobject]@{
            WorkflowName = 'publish'
            LocalRequested = $true
            PublishInvocation = [pscustomobject]@{IsLocal = $true; Target = '/x'}
        }
        Write-NovaPublishWorkflowContext -WorkflowContext $ctx
        Should -Invoke Write-NovaLocalWorkflowMode -Times 1 -ParameterFilter {$WorkflowName -eq 'publish'}
        Should -Invoke Write-NovaResolvedLocalPublishTarget -Times 1
    }
}
