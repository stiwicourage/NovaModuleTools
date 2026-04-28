function Invoke-NovaModuleSelfUpdate {
    [CmdletBinding()]
    param(
        [string]$ModuleName = 'NovaModuleTools',
        [switch]$AllowPrerelease
    )

    $updateParameters = Get-NovaModuleUpdateParameterMap -ModuleName $ModuleName -AllowPrereleaseRequested:$AllowPrerelease.IsPresent
    return Invoke-NovaModuleUpdateCommand -UpdateParameters $updateParameters
}
