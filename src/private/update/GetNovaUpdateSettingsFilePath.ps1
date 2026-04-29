function Get-NovaUpdateSettingsFilePath {
    [CmdletBinding()]
    param()

    return Join-Path (Get-NovaSettingsDirectoryPath -ApplicationName 'NovaModuleTools') 'settings.json'
}
