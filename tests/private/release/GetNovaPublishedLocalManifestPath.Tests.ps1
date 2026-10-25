BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaPublishedLocalManifestPath.ps1')
    . (Join-Path $projectRoot 'src/private/release/GetNovaLocalPublishVersionDirectory.ps1')
    . (Join-Path $projectRoot 'src/private/shared/ImportNovaBuiltModuleForCi.ps1')
}

Describe 'Get-NovaPublishedLocalManifestPath' -Tag 'LocalPublication' {
    It 'returns $null when the invocation is not local' {
        $invocation = [pscustomobject]@{IsLocal = $false; Target = '/a'; Parameters = @{ProjectInfo = [pscustomobject]@{ProjectName='X'}}}
        Get-NovaPublishedLocalManifestPath -PublishInvocation $invocation | Should -BeNullOrEmpty
    }

    It 'returns the exact built-version manifest even after a rebuild with stale ProjectInfo.Version' {
        $builtDirectory = Join-Path $TestDrive 'built'
        New-Item -Path $builtDirectory -ItemType Directory | Out-Null
        $builtManifest = Join-Path $builtDirectory 'X.psd1'
        Set-Content -LiteralPath $builtManifest -Value "@{ModuleVersion='1.2.3'}"
        $invocation = [pscustomobject]@{IsLocal = $true; Target = $TestDrive; Parameters = @{ProjectInfo = [pscustomobject]@{ProjectName='X'; OutputModuleDir=$builtDirectory; Version='1.2.3'}}}
        Get-NovaPublishedLocalManifestPath -PublishInvocation $invocation |
            Should -Be (Join-Path $TestDrive 'X/1.2.3/X.psd1')
        Set-Content -LiteralPath $builtManifest -Value "@{ModuleVersion='1.2.4'; PrivateData=@{PSData=@{Prerelease='preview'}}}"
        Get-NovaPublishedLocalManifestPath -PublishInvocation $invocation |
            Should -Be (Join-Path $TestDrive 'X/1.2.4/X.psd1')
    }
}
