function Get-NovaScaffoldModuleVersion {
    [CmdletBinding()]
    param()

    $module = $ExecutionContext.SessionState.Module
    if ($null -eq $module) {
        return $null
    }

    return $module.Version
}

