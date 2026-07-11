BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/WriteNovaUpdateNotificationPreference.ps1')

    function Write-NovaJsonFileData {param([string]$LiteralPath, $Value)}
    function Get-NovaUpdateSettingsFilePath {return '/tmp/settings.json'}
}

Describe 'Write-NovaUpdateNotificationPreference' {
    It 'writes the preference to the settings path via the shared JSON adapter' {
        Mock Get-NovaUpdateSettingsFilePath {return '/expected/path/settings.json'}
        Mock Write-NovaJsonFileData {}

        Write-NovaUpdateNotificationPreference -PrereleaseNotificationsEnabled $false

        Should -Invoke Write-NovaJsonFileData -Times 1 -ParameterFilter {
            $LiteralPath -eq '/expected/path/settings.json' -and
            $Value.PrereleaseNotificationsEnabled -eq $false
        }
    }
}
