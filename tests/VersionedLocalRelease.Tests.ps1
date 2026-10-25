# Cross-cutting coverage keeps the release rebuild, local publisher, and manifest identity together.
BeforeAll {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $projectRoot 'src/private/release/InvokeNovaReleaseWorkflow.ps1')
    . (Join-Path $projectRoot 'tests/private/release/InvokeNovaReleaseWorkflow.TestSupport.ps1')
    . (Join-Path $projectRoot 'src/private/shared/ImportNovaBuiltModuleForCi.ps1')
    . (Join-Path $projectRoot 'src/private/release/GetNovaLocalPublishVersionDirectory.ps1')
    . (Join-Path $projectRoot 'src/private/release/GetNovaPublishedLocalManifestPath.ps1')
    . (Join-Path $projectRoot 'src/private/release/PublishNovaBuiltModuleToDirectory.ps1')
    . (Join-Path $projectRoot 'src/private/release/ImportNovaPublishedLocalModule.ps1')
}

Describe 'Versioned local release' -Tag 'LocalPublication' {
    It 'publishes the rebuilt release version with stale project metadata and exposes an importable exact manifest' {
        $builtDirectory = Join-Path $TestDrive 'built'
        New-Item -ItemType Directory -Path $builtDirectory | Out-Null
        Set-Content -LiteralPath (Join-Path $builtDirectory 'NovaReleaseFixture.psm1') -Value ''
        $script:manifestPath = Join-Path $builtDirectory 'NovaReleaseFixture.psd1'
        $script:buildCalls = 0
        Mock Invoke-NovaBuild {
            $script:buildCalls += 1
            $builtVersion = if ($script:buildCalls -eq 1) { '1.2.3' } else { '1.2.4' }
            Set-Content -LiteralPath $script:manifestPath -Value "@{RootModule='NovaReleaseFixture.psm1'; ModuleVersion='$builtVersion'; PrivateData=@{PSData=@{Prerelease='preview'}}}"
        }
        Mock Update-NovaModuleVersion { return [pscustomobject]@{NewVersion='1.2.4-preview'} }
        Mock Write-Message {}
        Mock Write-Progress {}
        $project = [pscustomobject]@{ProjectName='NovaReleaseFixture'; OutputModuleDir=$builtDirectory; Version='1.2.3'}
        $publishParams = @{ProjectInfo=$project; ModuleDirectoryPath=(Join-Path $TestDrive 'modules')}
        $invocation = [pscustomobject]@{
            Action = (Get-Command Publish-NovaBuiltModuleToDirectory).ScriptBlock
            Parameters = $publishParams
            Target = $publishParams.ModuleDirectoryPath
            IsLocal = $true
        }
        $context = [pscustomobject]@{
            ProjectInfo=$project; WorkflowParams=@{}; PublishParams=$publishParams
            PublishInvocation=$invocation; SkipTestsRequested=$true
        }
        $result = Invoke-NovaReleaseWorkflow -WorkflowContext $context
        $result.NewVersion | Should -Be '1.2.4-preview'
        $publishedManifest = Get-NovaPublishedLocalManifestPath -PublishInvocation $invocation
        $publishedManifest | Should -Be (Join-Path $TestDrive 'modules/NovaReleaseFixture/1.2.4/NovaReleaseFixture.psd1')
        try {
            $module = Import-NovaPublishedLocalModule -ProjectName $project.ProjectName -ManifestPath $publishedManifest
            $module.Version.ToString() | Should -Be '1.2.4'
            $module.PrivateData.PSData.Prerelease | Should -Be 'preview'
            $module.ModuleBase | Should -Be (Split-Path -Parent $publishedManifest)
        } finally {
            Remove-Module NovaReleaseFixture -Force -ErrorAction SilentlyContinue
        }
    }
}
