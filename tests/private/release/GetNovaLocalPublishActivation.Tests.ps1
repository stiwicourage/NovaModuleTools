BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaLocalPublishActivation.ps1')

    function Get-NovaPublishedLocalManifestPath {param($PublishInvocation) return '/m/x.psd1'}
    function Import-NovaPublishedLocalModule {param($ProjectName, $ManifestPath)}
}

Describe 'Get-NovaLocalPublishActivation' {
    It 'returns $null when the invocation is not local' {
        Get-NovaLocalPublishActivation -PublishInvocation ([pscustomobject]@{IsLocal=$false}) | Should -BeNullOrEmpty
    }

    It 'returns a manifest path and import action when local' {
        $result = Get-NovaLocalPublishActivation -PublishInvocation ([pscustomobject]@{IsLocal=$true})
        $result.ManifestPath | Should -Be '/m/x.psd1'
        $result.ImportAction | Should -Not -BeNullOrEmpty
    }
}
