function Invoke-NovaModuleSelfUpdate {
    [CmdletBinding()]
    param(
        [string]$ModuleName = 'NovaModuleTools',
        [switch]$AllowPrerelease
    )

    $updateParameters = @{
        Name = $ModuleName
        ErrorAction = 'Stop'
    }

    if ($AllowPrerelease) {
        $updateParameters.AllowPrerelease = $true
    }

    return Update-Module @updateParameters
}
