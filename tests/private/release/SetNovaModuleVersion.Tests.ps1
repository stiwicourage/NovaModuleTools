BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/SetNovaModuleVersion.ps1')

    function Get-NovaVersionUpdatePlan {param($ProjectInfo, $Label, [switch]$PreviewRelease, [switch]$StableRelease) return [pscustomobject]@{ProjectFile='/tmp/project.json'; NewVersion=[semver]'1.2.4'}}
    function Read-ProjectJsonData {param($ProjectJsonPath) return [pscustomobject]@{Version='1.2.3'}}
    function Write-ProjectJsonData {param($ProjectJsonPath, $Data)}
}

Describe 'Get-NovaModuleVersionWriteResult' {
    It 'returns a structured write result' {
        $result = Get-NovaModuleVersionWriteResult -ProjectFile '/tmp/project.json' -PreviousVersion '1.0.0' -NewVersion '1.0.1' -Applied
        $result.PreviousVersion | Should -Be '1.0.0'
        $result.NewVersion | Should -Be '1.0.1'
        $result.Applied | Should -BeTrue
        $result.Target | Should -Be 'project.json'
    }
}

Describe 'Set-NovaModuleVersion' {
    It 'writes a new version and reports Applied = $true' {
        Mock Write-ProjectJsonData {}
        $result = Set-NovaModuleVersion -Label Patch -Confirm:$false
        $result.NewVersion | Should -Be '1.2.4'
        $result.PreviousVersion | Should -Be '1.2.3'
        $result.Applied | Should -BeTrue
        Should -Invoke Write-ProjectJsonData -Times 1
    }

    It 'returns Applied = $false under -WhatIf' {
        Mock Write-ProjectJsonData {}
        $result = Set-NovaModuleVersion -Label Patch -WhatIf
        $result.Applied | Should -BeFalse
        Should -Invoke Write-ProjectJsonData -Times 0
    }
}
