BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/ConvertFromNovaPSModuleUpdateResult.ps1')
}

Describe 'ConvertFrom-NovaPSModuleUpdateResult' {
    It 'returns the installed version and restart requirement for <Outcome> results' -ForEach @(
        @{Outcome = 'Installed'}
        @{Outcome = 'AlreadyInstalled'}
    ) {
        $result = [pscustomobject]@{Outcome = $Outcome; InstalledVersion = '2.0.0'; RestartRequired = $true}

        $converted = ConvertFrom-NovaPSModuleUpdateResult -Result $result

        $converted.InstalledVersion | Should -Be '2.0.0'
        $converted.RestartRequired | Should -BeTrue
    }

    It 'throws a descriptive error for <Outcome> results that did not install the update' -ForEach @(
        @{Outcome = 'Cancelled'}
        @{Outcome = 'WhatIf'}
        @{Outcome = 'Unexpected'}
    ) {
        $result = [pscustomobject]@{Outcome = $Outcome}

        {ConvertFrom-NovaPSModuleUpdateResult -Result $result} | Should -Throw "PSModuleUpdate did not install the update (outcome: $Outcome)."
    }
}
