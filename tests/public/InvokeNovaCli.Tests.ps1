BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/InvokeNovaCli.ps1')

    function Get-NovaCliInvocationContext {param($InvocationRequest, [switch]$WhatIfEnabled)
        $script:request = $InvocationRequest
        return [pscustomobject]@{Request=$InvocationRequest; WhatIf=[bool]$WhatIfEnabled}
    }
    function Invoke-NovaCliCommandRoute {param($InvocationContext) return [pscustomobject]@{Routed=$true; Command=$InvocationContext.Request.Command}}
}

Describe 'Invoke-NovaCli' {
    It 'defaults to --help when no command is provided' {
        (Invoke-NovaCli).Command | Should -Be '--help'
    }

    It 'forwards command and remaining arguments to the invocation context' {
        Invoke-NovaCli 'build' '--ci' '--override-warning' | Out-Null
        $script:request.Command | Should -Be 'build'
        $script:request.Arguments | Should -Be @('--ci','--override-warning')
    }
}
