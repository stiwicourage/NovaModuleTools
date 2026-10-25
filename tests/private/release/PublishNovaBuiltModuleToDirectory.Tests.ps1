BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/PublishNovaBuiltModuleToDirectory.ps1')
    . (Join-Path $projectRoot 'src/private/release/GetNovaLocalPublishVersionDirectory.ps1')
    . (Join-Path $projectRoot 'src/private/shared/ImportNovaBuiltModuleForCi.ps1')
}

Describe 'Publish-NovaBuiltModuleToDirectory' -Tag 'LocalPublication' {
    BeforeEach {
        $script:src = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $script:dest = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $sourceModule = Join-Path $script:src 'Sample'
        New-Item -ItemType Directory -Path $sourceModule -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $sourceModule 'Sample.psm1') -Value 'x'
        $script:manifestPath = Join-Path $sourceModule 'Sample.psd1'
        Set-Content -LiteralPath $script:manifestPath -Value "@{ModuleVersion='1.2.3'}"
        $script:project = [pscustomobject]@{ProjectName='Sample'; OutputModuleDir=$sourceModule; Version='0.0.1-stale'}
    }
    AfterEach {
        Remove-Item -LiteralPath $script:src -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:dest -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'creates a custom modules root and copies the complete built module into its numeric version' {
        Publish-NovaBuiltModuleToDirectory -ProjectInfo $script:project -ModuleDirectoryPath $script:dest
        Test-Path -LiteralPath (Join-Path $script:dest 'Sample/1.2.3/Sample.psm1') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $script:dest 'Sample/1.2.3/Sample.psd1') | Should -BeTrue
    }

    It 'replaces only the same numeric version for <Label> and preserves other versions and legacy flat files' -TestCases @(
        @{Label='stable'; Prerelease=''}
        @{Label='preview'; Prerelease='preview'}
    ) {
        param($Label, $Prerelease)
        Set-Content -LiteralPath $script:manifestPath -Value "@{ModuleVersion='1.2.3'; PrivateData=@{PSData=@{Prerelease='$Prerelease'}}}"
        New-Item -ItemType Directory -Path (Join-Path $script:dest 'Sample/1.2.3'), (Join-Path $script:dest 'Sample/1.0.0') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $script:dest 'Sample/1.2.3/old.txt') -Value 'old'
        Set-Content -LiteralPath (Join-Path $script:dest 'Sample/1.0.0/keep.txt') -Value 'previous'
        Set-Content -LiteralPath (Join-Path $script:dest 'Sample/Sample.psd1') -Value 'legacy'
        Publish-NovaBuiltModuleToDirectory -ProjectInfo $script:project -ModuleDirectoryPath $script:dest
        Test-Path -LiteralPath (Join-Path $script:dest 'Sample/1.2.3/old.txt') | Should -BeFalse
        Get-Content -LiteralPath (Join-Path $script:dest 'Sample/1.2.3/Sample.psm1') | Should -Be 'x' -Because "$Label must publish the new module"
        Get-Content -LiteralPath (Join-Path $script:dest 'Sample/1.0.0/keep.txt') | Should -Be 'previous'
        Get-Content -LiteralPath (Join-Path $script:dest 'Sample/Sample.psd1') | Should -Be 'legacy'
    }

    It 'uses built ModuleVersion <Version> without putting the prerelease label in the folder' -TestCases @(
        @{Version='1.2'}
        @{Version='1.2.3'}
        @{Version='1.2.3.4'}
    ) {
        param($Version)
        Set-Content -LiteralPath $script:manifestPath -Value "@{ModuleVersion='$Version'; PrivateData=@{PSData=@{Prerelease='preview'}}}"
        Publish-NovaBuiltModuleToDirectory -ProjectInfo $script:project -ModuleDirectoryPath $script:dest
        $published = Join-Path $script:dest "Sample/$Version/Sample.psd1"
        (Import-PowerShellDataFile -LiteralPath $published).PrivateData.PSData.Prerelease | Should -Be 'preview'
        Test-Path -LiteralPath (Join-Path $script:dest "Sample/$Version-preview") | Should -BeFalse
    }

    It 'does not create a modules root under WhatIf' {
        Publish-NovaBuiltModuleToDirectory -ProjectInfo $script:project -ModuleDirectoryPath $script:dest -WhatIf
        Test-Path -LiteralPath $script:dest | Should -BeFalse
    }

    It 'does not change an existing installation under WhatIf' {
        New-Item -ItemType Directory -Path (Join-Path $script:dest 'Sample/1.2.3') -Force | Out-Null
        $oldFile = Join-Path $script:dest 'Sample/1.2.3/old.txt'
        Set-Content -LiteralPath $oldFile -Value 'unchanged'
        Publish-NovaBuiltModuleToDirectory -ProjectInfo $script:project -ModuleDirectoryPath $script:dest -WhatIf
        Get-Content -LiteralPath $oldFile | Should -Be 'unchanged'
        Test-Path -LiteralPath (Join-Path $script:dest 'Sample/1.2.3/Sample.psm1') | Should -BeFalse
    }

    It 'rejects <Case> before deleting or creating destination content' -TestCases @(
        @{Case='invalid version'; Content="@{ModuleVersion='invalid'}"}
        @{Case='prerelease in ModuleVersion'; Content="@{ModuleVersion='1.2.3-preview'}"}
        @{Case='missing version'; Content='@{}'}
        @{Case='malformed manifest'; Content='@{'}
        @{Case='missing manifest'; Content=$null}
    ) {
        param($Case, $Content)
        if ($null -eq $Content) {
            Remove-Item -LiteralPath $script:manifestPath
        } else {
            Set-Content -LiteralPath $script:manifestPath -Value $Content
        }
        { Publish-NovaBuiltModuleToDirectory -ProjectInfo $script:project -ModuleDirectoryPath $script:dest } | Should -Throw -Because $Case
        Test-Path -LiteralPath $script:dest | Should -BeFalse
        New-Item -ItemType Directory -Path (Join-Path $script:dest 'Sample/1.2.3') -Force | Out-Null
        $oldFile = Join-Path $script:dest 'Sample/1.2.3/old.txt'
        Set-Content -LiteralPath $oldFile -Value 'untouched'
        { Publish-NovaBuiltModuleToDirectory -ProjectInfo $script:project -ModuleDirectoryPath $script:dest } | Should -Throw
        Get-Content -LiteralPath $oldFile | Should -Be 'untouched'
        Test-Path -LiteralPath (Join-Path $script:dest 'Sample/Sample.psm1') | Should -BeFalse
    }
}
