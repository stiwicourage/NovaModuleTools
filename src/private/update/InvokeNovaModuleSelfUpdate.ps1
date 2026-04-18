function Invoke-NovaModuleSelfUpdate {
    [CmdletBinding()]
    param(
        [string]$ModuleName = 'NovaModuleTools',
        [switch]$AllowPrerelease
    )

    if ($AllowPrerelease) {
        return Update-Module $ModuleName -AllowPrerelease
    }

    return Update-Module $ModuleName
}
