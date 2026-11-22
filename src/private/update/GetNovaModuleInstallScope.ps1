function Get-NovaModuleInstallScope {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$ModuleBase
    )

    $separator = [System.IO.Path]::DirectorySeparatorChar
    $allUsersRoot = [System.IO.Path]::GetFullPath((Get-NovaAllUsersModuleRoot)).TrimEnd($separator) + $separator
    $modulePath = [System.IO.Path]::GetFullPath($ModuleBase)
    if ($modulePath.StartsWith($allUsersRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return 'AllUsers'
    }

    return 'CurrentUser'
}

function Get-NovaAllUsersModuleRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($IsWindows) {
        return Join-Path (Join-Path ([Environment]::GetFolderPath('ProgramFiles')) 'PowerShell') 'Modules'
    }

    return '/usr/local/share/powershell/Modules'
}
