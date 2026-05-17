BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/ReadNovaUpdateNotificationPreference.ps1')

    function Read-NovaJsonFileData {param([string]$LiteralPath)}
    function Get-NovaUpdateSettingsFilePath {return '/tmp/settings.json'}
}

Describe 'Get-NovaDefaultUpdateNotificationPreference' {
    It 'defaults prerelease notifications to enabled' {
        $default = Get-NovaDefaultUpdateNotificationPreference
        $default.PrereleaseNotificationsEnabled | Should -BeTrue
    }
}

Describe 'Read-NovaUpdateNotificationPreference' {
    It 'falls back to the default preference when no settings file exists' {
        Mock Read-NovaJsonFileData {return $null}

        $result = Read-NovaUpdateNotificationPreference
        $result.PrereleaseNotificationsEnabled | Should -BeTrue
    }

    It 'returns the stored preference when settings file content is present' {
        Mock Read-NovaJsonFileData {return [pscustomobject]@{PrereleaseNotificationsEnabled = $false}}

        (Read-NovaUpdateNotificationPreference).PrereleaseNotificationsEnabled | Should -BeFalse
    }

    It 'coerces the stored preference to a boolean' {
        Mock Read-NovaJsonFileData {return [pscustomobject]@{PrereleaseNotificationsEnabled = 'false'}}

        (Read-NovaUpdateNotificationPreference).PrereleaseNotificationsEnabled | Should -BeTrue
    }
}
