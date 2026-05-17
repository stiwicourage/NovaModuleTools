BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaPublishedLocalManifestPath.ps1')
}

Describe 'Get-NovaPublishedLocalManifestPath' {
    It 'returns $null when the invocation is not local' {
        $invocation = [pscustomobject]@{IsLocal = $false; Target = '/a'; Parameters = @{ProjectInfo = [pscustomobject]@{ProjectName='X'}}}
        Get-NovaPublishedLocalManifestPath -PublishInvocation $invocation | Should -BeNullOrEmpty
    }

    It 'returns Target/Name/Name.psd1 when local' {
        $invocation = [pscustomobject]@{IsLocal = $true; Target = '/m'; Parameters = @{ProjectInfo = [pscustomobject]@{ProjectName='X'}}}
        Get-NovaPublishedLocalManifestPath -PublishInvocation $invocation |
            Should -Be (Join-Path (Join-Path '/m' 'X') 'X.psd1')
    }
}
