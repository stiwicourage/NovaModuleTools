BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaPrereleaseModuleUpdateConfirmationPrompt.ps1')
}

Describe 'Get-NovaPrereleaseModuleUpdateConfirmationPrompt' {
    BeforeAll {
        $script:prompt = Get-NovaPrereleaseModuleUpdateConfirmationPrompt -CurrentVersion '1.0.0' -TargetVersion '2.0.0-beta1'
    }

    It 'uses the expected confirmation caption' {
        $script:prompt.Caption | Should -Be 'Confirm prerelease NovaModuleTools update'
    }

    It 'includes the current and target versions in the message' {
        $script:prompt.Message | Should -Match '1\.0\.0'
        $script:prompt.Message | Should -Match '2\.0\.0-beta1'
    }

    It 'offers Yes and No choices with No as the default' {
        $script:prompt.Choice.Keys | Should -Be @('Y','N')
        $script:prompt.Choice['Y'] | Should -Be 'Yes'
        $script:prompt.Choice['N'] | Should -Be 'No'
        $script:prompt.Default | Should -Be 'N'
    }
}
