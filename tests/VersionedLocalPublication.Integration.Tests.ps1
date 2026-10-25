# Cross-cutting coverage owns the built public publish command, filesystem layout, and activation.
BeforeAll {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $projectRoot | Out-Null
}

Describe 'Versioned local publication integration' {
    BeforeEach {
        $script:fixture = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $script:modulesRoot = Join-Path $script:fixture 'modules'
        $source = Join-Path $script:fixture 'src/public'
        New-Item -ItemType Directory -Path $source -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $source 'GetLocalPublishGreeting.ps1') -Value "function Get-LocalPublishGreeting { 'published' }"
        $script:metadata = @{
            ProjectName = 'NovaLocalPublishFixture'
            Version = '1.2.3'
            Description = 'Isolated local publication fixture'
            Manifest = @{PowerShellHostVersion='7.4'; GUID=[guid]::NewGuid().ToString(); Author='Nova test fixture'}
        }
    }

    AfterEach {
        Remove-Module NovaLocalPublishFixture -Force -ErrorAction SilentlyContinue
    }

    It '<Surface> publishes and activates stable then same-base preview without removing sibling versions or legacy files' -TestCases @(
        @{Surface='cmdlet'}
        @{Surface='CLI'}
    ) {
        param($Surface)
        $publishAction = if ($Surface -eq 'CLI') {
            { Invoke-NovaCli -Command publish -Arguments @('-l', '-s', '--path', $script:modulesRoot) }
        } else {
            { Publish-NovaModule -Local -SkipTests -ModuleDirectoryPath $script:modulesRoot }
        }
        $legacyRoot = Join-Path $script:modulesRoot 'NovaLocalPublishFixture'
        New-Item -ItemType Directory -Path (Join-Path $legacyRoot '1.0.0') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $legacyRoot 'legacy.txt') -Value 'legacy'
        Set-Content -LiteralPath (Join-Path $legacyRoot '1.0.0/keep.txt') -Value 'previous'
        foreach ($version in @('1.2.3', '1.2.3-preview')) {
            $script:metadata.Version = $version
            $script:metadata | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $script:fixture 'project.json')
            Invoke-NovaPublicCommandIntegrationInLocation -Path $script:fixture -ScriptBlock $publishAction
            $installedManifest = Join-Path $legacyRoot '1.2.3/NovaLocalPublishFixture.psd1'
            Test-Path -LiteralPath $installedManifest | Should -BeTrue
            (Get-Module NovaLocalPublishFixture).ModuleBase | Should -Be (Split-Path -Parent $installedManifest)
            Get-LocalPublishGreeting | Should -Be 'published'
        }
        (Import-PowerShellDataFile -LiteralPath $installedManifest).PrivateData.PSData.Prerelease | Should -Be 'preview'
        Get-Content -LiteralPath (Join-Path $legacyRoot 'legacy.txt') | Should -Be 'legacy'
        Get-Content -LiteralPath (Join-Path $legacyRoot '1.0.0/keep.txt') | Should -Be 'previous'
        Test-Path -LiteralPath (Join-Path $legacyRoot '1.2.3-preview') | Should -BeFalse
    }

    It '<Surface> leaves the disposable project and modules root unchanged under public WhatIf' -TestCases @(
        @{Surface='cmdlet'}
        @{Surface='CLI'}
    ) {
        param($Surface)
        $publishAction = if ($Surface -eq 'CLI') {
            { Invoke-NovaCli -Command publish -Arguments @('-l', '-s', '--path', $script:modulesRoot) -WhatIf }
        } else {
            { Publish-NovaModule -Local -SkipTests -ModuleDirectoryPath $script:modulesRoot -WhatIf }
        }
        $script:metadata | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $script:fixture 'project.json')
        Invoke-NovaPublicCommandIntegrationInLocation -Path $script:fixture -ScriptBlock $publishAction
        Test-Path -LiteralPath $script:modulesRoot | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $script:fixture 'dist') | Should -BeFalse
        Get-Module NovaLocalPublishFixture | Should -BeNullOrEmpty
    }
}
