BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaLocalPublishVersionDirectory.ps1')
    . (Join-Path $projectRoot 'src/private/shared/ImportNovaBuiltModuleForCi.ps1')
}

Describe 'Get-NovaLocalPublishVersionDirectory' -Tag 'LocalPublication' {
    BeforeEach {
        $script:manifest = Join-Path $TestDrive 'Sample.psd1'
        $script:project = [pscustomobject]@{ProjectName='Sample'; OutputModuleDir=$TestDrive; Version='0.0.1-stale'}
    }

    It 'uses numeric ModuleVersion <Version> from the built manifest' -TestCases @(
        @{Version='1.2'}
        @{Version='1.2.3'}
        @{Version='1.2.3.4'}
    ) {
        param($Version)
        Set-Content -LiteralPath $script:manifest -Value "@{ModuleVersion='$Version'; PrivateData=@{PSData=@{Prerelease='preview'}}}"
        Get-NovaLocalPublishVersionDirectory -ProjectInfo $script:project -ModuleDirectoryPath $TestDrive |
            Should -Be (Join-Path $TestDrive "Sample/$Version")
    }

    It 'rejects a manifest without a numeric version' {
        Set-Content -LiteralPath $script:manifest -Value '@{}'
        { Get-NovaLocalPublishVersionDirectory -ProjectInfo $script:project -ModuleDirectoryPath $TestDrive } |
            Should -Throw '*must contain a numeric ModuleVersion*'
    }

    It 'surfaces a missing built manifest' {
        { Get-NovaLocalPublishVersionDirectory -ProjectInfo $script:project -ModuleDirectoryPath $TestDrive } |
            Should -Throw
    }
}
