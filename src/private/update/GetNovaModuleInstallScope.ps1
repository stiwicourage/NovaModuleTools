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
    param(
        [bool]$IsWindowsPlatform = $IsWindows,
        [string]$ProgramFilesPath = [Environment]::GetFolderPath('ProgramFiles')
    )

    if ($IsWindowsPlatform) {
        return Join-Path (Join-Path $ProgramFilesPath 'PowerShell') 'Modules'
    }

    return '/usr/local/share/powershell/Modules'
}
