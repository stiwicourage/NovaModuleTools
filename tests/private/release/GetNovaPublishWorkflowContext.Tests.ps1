BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaPublishWorkflowContext.ps1')
    . (Join-Path $projectRoot 'src/private/release/GetNovaPublishOptionValue.ps1')
    . (Join-Path $projectRoot 'src/private/release/GetNovaResolvedPublishParameterMap.ps1')

    function Resolve-NovaPublishInvocation {param($ProjectInfo, $Repository, $ModuleDirectoryPath, $ApiKey)
        return [pscustomobject]@{
            IsLocal = [string]::IsNullOrEmpty($Repository)
            Target = if ($Repository) {$Repository} else {$ModuleDirectoryPath}
            Parameters = @{ProjectInfo = $ProjectInfo}
        }
    }
    function Get-NovaLocalPublishActivation {param($PublishInvocation) return 'activation'}
    function Get-NovaPublishWorkflowOperation {param([bool]$IsLocal, [switch]$Release, [switch]$SkipTestsRequested) return 'operation'}
}

Describe 'Get-NovaPublishWorkflowContext' {
    It 'builds the workflow context with required fields' {
        $ctx = Get-NovaPublishWorkflowContext -ProjectInfo ([pscustomobject]@{ProjectName='X'}) -PublishOption @{Repository='r'} -WorkflowSettings @{WorkflowName='publish'}
        $ctx.WorkflowName | Should -Be 'publish'
        $ctx.LocalRequested | Should -BeFalse
        $ctx.PublishInvocation.Target | Should -Be 'r'
        $ctx.LocalPublishActivation | Should -BeNullOrEmpty
        $ctx.Operation | Should -Be 'operation'
    }

    It 'includes local publish activation when configured' {
        $ctx = Get-NovaPublishWorkflowContext -ProjectInfo ([pscustomobject]@{ProjectName='X'}) -PublishOption @{Local=$true; ModuleDirectoryPath='/m'} -WorkflowSettings @{WorkflowName='publish'; IncludeLocalPublishActivation=$true}
        $ctx.LocalRequested | Should -BeTrue
        $ctx.LocalPublishActivation | Should -Be 'activation'
    }
}
