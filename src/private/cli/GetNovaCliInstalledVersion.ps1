function Get-NovaCliInstalledVersion {
    [CmdletBinding()]
    param()

    return $ExecutionContext.SessionState.Module.Version.ToString()
}

