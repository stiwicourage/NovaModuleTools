function Get-NovaSettingsDirectoryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApplicationName
    )

    return Join-Path (Get-NovaSettingsRootPath) $ApplicationName
}

function Get-NovaSettingsRootPath {
    [CmdletBinding()]
    param()

    if ($IsWindows) {
        $appData = Get-NovaEnvironmentVariableValue -Name 'APPDATA'
        if (Test-NovaConfiguredValue -Value $appData) {
            return $appData
        }
    }

    $xdgConfigHome = Get-NovaEnvironmentVariableValue -Name 'XDG_CONFIG_HOME'
    if (Test-NovaConfiguredValue -Value $xdgConfigHome) {
        return $xdgConfigHome
    }

    return Join-Path $HOME '.config'
}

