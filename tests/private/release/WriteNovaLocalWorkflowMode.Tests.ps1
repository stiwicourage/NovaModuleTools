BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/WriteNovaLocalWorkflowMode.ps1')
}

Describe 'Write-NovaLocalWorkflowMode' {
    It 'emits a verbose message when -LocalRequested' {
        Write-NovaLocalWorkflowMode -WorkflowName 'publish' -LocalRequested -Verbose 4>&1 |
            Where-Object {$_ -is [System.Management.Automation.VerboseRecord]} |
            ForEach-Object {$_.Message} | Should -Match 'local publish'
    }

    It 'emits nothing when -LocalRequested is not set' {
        $verbose = Write-NovaLocalWorkflowMode -WorkflowName 'publish' -Verbose 4>&1 |
            Where-Object {$_ -is [System.Management.Automation.VerboseRecord]}
        $verbose | Should -BeNullOrEmpty
    }
}
