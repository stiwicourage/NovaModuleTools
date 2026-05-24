BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaUpdateNotificationPreferenceStatus.ps1')

    function Read-NovaUpdateNotificationPreference {return [pscustomobject]@{PrereleaseNotificationsEnabled = $true}}
    function Get-NovaUpdateSettingsFilePath {return '/tmp/nova-settings.json'}
}

Describe 'Get-NovaUpdateNotificationPreferenceStatus' {
    It 'returns the stored preference along with the settings file path' {
        Mock Read-NovaUpdateNotificationPreference {return [pscustomobject]@{PrereleaseNotificationsEnabled = $false}}
        Mock Get-NovaUpdateSettingsFilePath {return '/some/path/settings.json'}
        Mock Test-Path {return $true}
        Mock Write-Verbose {}

        $status = Get-NovaUpdateNotificationPreferenceStatus

        $status.PrereleaseNotificationsEnabled | Should -BeFalse
        $status.StableReleaseNotificationsEnabled | Should -BeTrue
        $status.SettingsPath | Should -Be '/some/path/settings.json'
        Assert-MockCalled Write-Verbose -Times 1 -ParameterFilter {
            $Message -eq 'Prerelease self-updates are disabled. Stable self-updates remain available. Settings file: /some/path/settings.json'
        }
    }

    It 'explains when the default preference is being used because the settings file is missing' {
        Mock Read-NovaUpdateNotificationPreference {return [pscustomobject]@{PrereleaseNotificationsEnabled = $true}}
        Mock Get-NovaUpdateSettingsFilePath {return '/some/path/settings.json'}
        Mock Test-Path {return $false}
        Mock Write-Verbose {}

        $status = Get-NovaUpdateNotificationPreferenceStatus

        $status.PrereleaseNotificationsEnabled | Should -BeTrue
        $status.SettingsPath | Should -Be '/some/path/settings.json'
        Assert-MockCalled Write-Verbose -Times 1 -ParameterFilter {
            $Message -eq 'No settings file was found at /some/path/settings.json. Using the default setting: prerelease self-updates are enabled. Stable self-updates remain available. Use Set-NovaUpdateNotificationPreference to store a different preference.'
        }
    }
}
