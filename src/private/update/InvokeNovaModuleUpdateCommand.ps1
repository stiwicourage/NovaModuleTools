function Get-NovaModuleUpdateParameterMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)][bool]$AllowPrereleaseRequested
    )

    $parameters = @{
        Name = $ModuleName
        ErrorAction = 'Stop'
    }
    if ($AllowPrereleaseRequested) {
        $parameters.AllowPrerelease = $true
    }

    return $parameters
}

function Invoke-NovaModuleUpdateCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$UpdateParameters
    )

    return Update-Module @UpdateParameters
}
