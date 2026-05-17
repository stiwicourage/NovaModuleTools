BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaResolvedPublishParameterMap.ps1')
}

Describe 'Get-NovaResolvedPublishParameterMap' {
    It 'combines invocation parameters with workflow params' {
        $invocation = [pscustomobject]@{Parameters = @{Path='/a'; Repository='r'}}
        $result = Get-NovaResolvedPublishParameterMap -PublishInvocation $invocation -WorkflowParams @{Verbose=$true}
        $result.Path | Should -Be '/a'
        $result.Repository | Should -Be 'r'
        $result.Verbose | Should -BeTrue
    }

    It 'lets workflow params override invocation parameters with the same key' {
        $invocation = [pscustomobject]@{Parameters = @{Path='/a'}}
        $result = Get-NovaResolvedPublishParameterMap -PublishInvocation $invocation -WorkflowParams @{Path='/b'}
        $result.Path | Should -Be '/b'
    }
}
