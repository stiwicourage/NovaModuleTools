. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tests/TestHelpers/PublicCommandIntegration.ps1')

BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Get-NovaUpdateNotificationPreference integration' {
    It 'returns the default preference from an isolated settings root in the built module' {
        $isolatedSettingsRoot = Join-Path $TestDrive 'config-root'
        $expectedSettingsPath = Join-Path (Join-Path $isolatedSettingsRoot 'NovaModuleTools') 'settings.json'
        $originalAppData = $env:APPDATA
        $originalXdgConfigHome = $env:XDG_CONFIG_HOME

        New-Item -ItemType Directory -Path $isolatedSettingsRoot -Force | Out-Null
        $env:APPDATA = $isolatedSettingsRoot
        $env:XDG_CONFIG_HOME = $isolatedSettingsRoot

        try {
            $result = Get-NovaUpdateNotificationPreference
        } finally {
            if ($null -eq $originalAppData) {
                Remove-Item Env:APPDATA -ErrorAction SilentlyContinue
            } else {
                $env:APPDATA = $originalAppData
            }

            if ($null -eq $originalXdgConfigHome) {
                Remove-Item Env:XDG_CONFIG_HOME -ErrorAction SilentlyContinue
            } else {
                $env:XDG_CONFIG_HOME = $originalXdgConfigHome
            }
        }

        $result.PrereleaseNotificationsEnabled | Should -BeTrue
        $result.StableReleaseNotificationsEnabled | Should -BeTrue
        $result.SettingsPath | Should -Be $expectedSettingsPath
    }
}
