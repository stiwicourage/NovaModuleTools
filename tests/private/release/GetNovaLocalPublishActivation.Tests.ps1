BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaLocalPublishActivation.ps1')

    function Get-NovaPublishedLocalManifestPath {param($PublishInvocation) return $PublishInvocation}
    function Import-NovaPublishedLocalModule {param($ProjectName, $ManifestPath) return "$ProjectName/$ManifestPath"}
}

Describe 'Get-NovaLocalPublishActivation' -Tag 'LocalPublication' {
    It 'returns $null when the invocation is not local' {
        Get-NovaLocalPublishActivation -PublishInvocation ([pscustomobject]@{IsLocal=$false}) | Should -BeNullOrEmpty
    }

    It 'defers the manifest path until publication while capturing the import action' {
        Mock Get-NovaPublishedLocalManifestPath {throw 'Build output does not exist yet'}
        $result = Get-NovaLocalPublishActivation -PublishInvocation ([pscustomobject]@{IsLocal=$true})
        $result.ManifestPath | Should -BeNullOrEmpty
        $result.ImportAction | Should -Not -BeNullOrEmpty
        Should -Invoke Get-NovaPublishedLocalManifestPath -Times 0
    }
}
