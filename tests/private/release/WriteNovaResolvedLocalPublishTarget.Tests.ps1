BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/WriteNovaResolvedLocalPublishTarget.ps1')
}

Describe 'Write-NovaResolvedLocalPublishTarget' {
    It 'writes a verbose message when the invocation is local' {
        $invocation = [pscustomobject]@{IsLocal = $true; Target = '/m/path'}
        Write-NovaResolvedLocalPublishTarget -PublishInvocation $invocation -Verbose 4>&1 |
            Where-Object {$_ -is [System.Management.Automation.VerboseRecord]} |
            ForEach-Object {$_.Message} | Should -Match '/m/path'
    }

    It 'writes nothing when the invocation is not local' {
        $invocation = [pscustomobject]@{IsLocal = $false; Target = '/m/path'}
        $verbose = Write-NovaResolvedLocalPublishTarget -PublishInvocation $invocation -Verbose 4>&1 |
            Where-Object {$_ -is [System.Management.Automation.VerboseRecord]}
        $verbose | Should -BeNullOrEmpty
    }
}
