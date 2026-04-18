function Get-NovaUpdateSettingsFilePath {
    [CmdletBinding()]
    param()

    $settingsRoot = if ($IsWindows -and -not [string]::IsNullOrWhiteSpace($env:APPDATA)) {
        Join-Path $env:APPDATA 'NovaModuleTools'
    }
    elseif (-not [string]::IsNullOrWhiteSpace($env:XDG_CONFIG_HOME)) {
        Join-Path $env:XDG_CONFIG_HOME 'NovaModuleTools'
    }
    else {
        Join-Path (Join-Path $HOME '.config') 'NovaModuleTools'
    }

    return Join-Path $settingsRoot 'settings.json'
}

